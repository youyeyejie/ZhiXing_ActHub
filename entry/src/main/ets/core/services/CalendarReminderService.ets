import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import { AppPreferenceKey } from '../../app/AppConstants';
import { AppDatabase } from '../database/AppDatabase';
import { UserDatabase } from '../database/UserDatabase';
import { Plan } from '../models/Plan';
import { PlanRepository } from '../repositories/PlanRepository';
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';

const CALENDAR_PERMISSIONS: Array<Permissions> = [
  'ohos.permission.READ_CALENDAR',
  'ohos.permission.WRITE_CALENDAR',
];

/**
 * 类功能简介：
 * - 通过 Calendar Kit 为日程注册系统日历事件，借助系统日历完成提醒。
 * - `Plan.reminderId` 当前复用为系统日历 `eventId`。
 *
 * 提醒生命周期说明：
 * - 用户登录、注册、恢复会话时，认证链路会确保 `planReminderEnabled` 默认值存在；当前默认策略为“缺省即开启”。
 * - 应用启动完成后，应用层会自动请求一次日历权限；若授权成功且当前用户已登录，会立即触发一次全量对账。
 * - 创建日程时，页面层先写入 Plan，再调用 `syncPlanReminderRecord(plan)`；若符合提醒条件则创建系统日历事件，并把 `notifyVersion` 追平到 `version`。
 * - 编辑日程时，页面层先保存 Plan；只有标题、开始/结束时间、描述、提醒开关这些会影响通知的字段变更时，才会递增 `version`，再调用 `syncPlanReminderRecord(plan)`。
 * - 地点、日程类型等不影响通知的字段变更，不会递增 `version`，也不会更新系统日历事件。
 * - 删除日程时，页面层在真正提交删除的那一刻调用 `clearPlanReminderRecord(plan)` 删除系统日历事件；进入撤销等待态不会改动提醒。
 * - 开关“日历提醒”时，设置页调用 `registerPlanReminder()` 或 `cancelPlanReminder()` 进行全量补建/清理。
 * - 冷启动恢复登录后，应用层调用 `registerPlanReminder()` 做一次全量对账；这里只补缺失事件和清理失效事件，不会更新已有事件，避免重复触发系统提醒。
 *
 * 当前调用处：
 * - `AppStates.syncCalendarRemindersForCurrentUser()`：登录、注册、恢复会话后的全量对账。
 * - `AppStates.tryRequestCalendarPermissionOnLaunch()`：启动时自动申请日历权限，授权成功后触发一次全量对账。
 * - `SettingsPanel.handleReminderToggle()`：总开关开启/关闭时的全量补建或清理。
 * - `PlanPageState.createPlan()`：新建日程后的单条注册。
 * - `PlanPageState.updatePlan()`：日程内容变更后的单条最小更新。
 * - `PlanPageState.commitDeletePlan()`：真正删除时的单条清理。
 */
export class CalendarReminderService {
  private static readonly CALENDAR_NAME: string = 'ZhixingActHub';
  private static readonly CALENDAR_DISPLAY_NAME: string = '知行日程提醒';
  private static readonly REMINDER_MINUTES: number = 10;
  private static readonly MINUTE_MS: number = 60 * 1000;

  private static calendar: calendarManager.Calendar | null = null;

  private readonly planRepository: PlanRepository = new PlanRepository();
  private readonly userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();

  private getAbilityContext(): common.UIAbilityContext | null {
    try {
      return AppDatabase.getInstance().getContext() as common.UIAbilityContext;
    } catch (_error) {
      return null;
    }
  }

  private normalizeReminderFlag(value: number): number {
    return value === 1 ? 1 : 0;
  }

  private isValidEventId(value: number): boolean {
    return value > 0;
  }

  private buildEventTitle(plan: Plan): string {
    const content = `${plan.content}`.trim();
    return content.length > 0 ? content : '未命名日程';
  }

  private buildEventDescription(plan: Plan): string {
    return `${plan.description}`.trim();
  }

  private buildPlanEvent(plan: Plan): calendarManager.Event {
    const event: calendarManager.Event = {
      title: this.buildEventTitle(plan),
      type: calendarManager.EventType.NORMAL,
      startTime: plan.startTime,
      endTime: plan.endTime > plan.startTime ? plan.endTime : plan.startTime + 60 * 60 * 1000,
      reminderTime: [CalendarReminderService.REMINDER_MINUTES],
      description: this.buildEventDescription(plan),
    };
    return event;
  }

  private getReminderTriggerTime(plan: Plan): number {
    return plan.startTime - CalendarReminderService.REMINDER_MINUTES * CalendarReminderService.MINUTE_MS;
  }

  private hasReminderWindowStarted(plan: Plan, now: number): boolean {
    return this.getReminderTriggerTime(plan) <= now;
  }

  private normalizeVersion(value: number): number {
    return value > 0 ? value : 0;
  }

  private hasSyncedNotifyVersion(plan: Plan): boolean {
    return this.normalizeVersion(plan.notifyVersion) === this.normalizeVersion(plan.version);
  }

  private async ensureCalendar(): Promise<calendarManager.Calendar | null> {
    if (CalendarReminderService.calendar !== null) {
      return CalendarReminderService.calendar;
    }

    const context = this.getAbilityContext();
    if (context === null) {
      return null;
    }

    try {
      const manager = calendarManager.getCalendarManager(context);
      const account: calendarManager.CalendarAccount = {
        name: CalendarReminderService.CALENDAR_NAME,
        type: calendarManager.CalendarType.LOCAL,
        displayName: CalendarReminderService.CALENDAR_DISPLAY_NAME,
      };
      let calendar: calendarManager.Calendar;
      try {
        calendar = await manager.getCalendar(account);
      } catch (_getError) {
        calendar = await manager.createCalendar(account);
      }
      const config: calendarManager.CalendarConfig = {
        enableReminder: true,
        color: '#2B7FFF',
      };
      await calendar.setConfig(config);
      CalendarReminderService.calendar = calendar;
      return calendar;
    } catch (_error) {
      return null;
    }
  }

  async requestCalendarPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const result = await manager.requestPermissionsFromUser(context, CALENDAR_PERMISSIONS);
      if (!this.isPermissionRequestGranted(result)) {
        return false;
      }
      const calendar = await this.ensureCalendar();
      return calendar !== null;
    } catch (_error) {
      return false;
    }
  }

  private isPermissionRequestGranted(result: PermissionRequestResult): boolean {
    for (let index = 0; index < result.authResults.length; index++) {
      if (result.authResults[index] !== 0) {
        return false;
      }
    }
    return true;
  }

  private async isPlanReminderSwitchEnabled(): Promise<boolean> {
    try {
      return await this.userPreferenceRepository.getBoolean(AppPreferenceKey.PLAN_REMINDER_ENABLED, false);
    } catch (_error) {
      return false;
    }
  }

  private async addPlanEvent(plan: Plan): Promise<number> {
    const calendar = await this.ensureCalendar();
    if (calendar === null) {
      return 0;
    }

    try {
      return await calendar.addEvent(this.buildPlanEvent(plan));
    } catch (_error) {
      return 0;
    }
  }

  private async updatePlanEvent(plan: Plan): Promise<boolean> {
    const calendar = await this.ensureCalendar();
    if (calendar === null || !this.isValidEventId(plan.reminderId)) {
      return false;
    }

    try {
      const event: calendarManager.Event = this.buildPlanEvent(plan);
      event.id = plan.reminderId;
      await calendar.updateEvent(event);
      return true;
    } catch (_error) {
      return false;
    }
  }

  private async deletePlanEvent(eventId: number): Promise<boolean> {
    const calendar = await this.ensureCalendar();
    if (calendar === null || !this.isValidEventId(eventId)) {
      return false;
    }

    try {
      await calendar.deleteEvent(eventId);
      return true;
    } catch (_error) {
      return false;
    }
  }

  /**
   * 单条提醒最小更新入口。
   * - 页面层的创建/编辑只调用这里。
   * - 若已进入提醒窗口，则不再改写已有事件，避免重进应用或临近开始时重复通知。
   */
  async syncPlanReminderRecord(plan: Plan): Promise<boolean> {
    const remindEnabled = this.normalizeReminderFlag(plan.enableRemind) === 1;
    const switchEnabled = await this.isPlanReminderSwitchEnabled();
    const now = Date.now();

    if (!remindEnabled || !switchEnabled || plan.startTime <= now) {
      return this.clearPlanReminderRecord(plan);
    }

    if (this.hasReminderWindowStarted(plan, now)) {
      return false;
    }

    if (this.isValidEventId(plan.reminderId)) {
      if (this.hasSyncedNotifyVersion(plan)) {
        return false;
      }
      const updated = await this.updatePlanEvent(plan);
      if (updated) {
        const changed = !this.hasSyncedNotifyVersion(plan);
        plan.notifyVersion = plan.version;
        return changed;
      }
    }

    if (this.isValidEventId(plan.reminderId)) {
      await this.deletePlanEvent(plan.reminderId);
      plan.reminderId = 0;
    }

    const eventId = await this.addPlanEvent(plan);
    if (!this.isValidEventId(eventId)) {
      if (plan.reminderId !== 0) {
        plan.reminderId = 0;
        plan.notifyVersion = 0;
        return true;
      }
      return false;
    }

    const changed = plan.reminderId !== eventId || !this.hasSyncedNotifyVersion(plan);
    plan.reminderId = eventId;
    plan.notifyVersion = plan.version;
    return changed;
  }

  async clearPlanReminderRecord(plan: Plan): Promise<boolean> {
    const hadNotifyVersion = this.normalizeVersion(plan.notifyVersion) > 0;
    if (!this.isValidEventId(plan.reminderId)) {
      if (hadNotifyVersion) {
        plan.notifyVersion = 0;
        return true;
      }
      return false;
    }

    await this.deletePlanEvent(plan.reminderId);
    plan.reminderId = 0;
    plan.notifyVersion = 0;
    return true;
  }

  /**
   * 全量对账入口。
   * - 只做“补漏”和“清理”。
   * - 对已有 reminderId 的记录，不主动 updateEvent，避免应用重进时重复触发系统提醒。
   */
  async registerPlanReminder(): Promise<void> {
    if (!UserDatabase.getInstance().isReady()) {
      return;
    }

    const switchEnabled = await this.isPlanReminderSwitchEnabled();
    if (!switchEnabled) {
      await this.cancelPlanReminder();
      return;
    }

    const plans = await this.planRepository.findAll();
    for (let index = 0; index < plans.length; index++) {
      const plan = plans[index];
      const changed = await this.reconcilePlanReminderRecord(plan);
      if (changed) {
        await this.planRepository.save(plan);
      }
    }
  }

  async cancelPlanReminder(): Promise<void> {
    if (!UserDatabase.getInstance().isReady()) {
      return;
    }

    const plans = await this.planRepository.findAll();
    for (let index = 0; index < plans.length; index++) {
      const plan = plans[index];
      const changed = await this.clearPlanReminderRecord(plan);
      if (changed) {
        await this.planRepository.save(plan);
      }
    }
  }

  private async reconcilePlanReminderRecord(plan: Plan): Promise<boolean> {
    const remindEnabled = this.normalizeReminderFlag(plan.enableRemind) === 1;
    const switchEnabled = await this.isPlanReminderSwitchEnabled();
    const now = Date.now();

    if (!remindEnabled || !switchEnabled || plan.startTime <= now) {
      return this.clearPlanReminderRecord(plan);
    }

    if (this.isValidEventId(plan.reminderId)) {
      if (!this.hasSyncedNotifyVersion(plan)) {
        plan.notifyVersion = plan.version;
        return true;
      }
      return false;
    }

    if (this.hasReminderWindowStarted(plan, now)) {
      return false;
    }

    const eventId = await this.addPlanEvent(plan);
    if (!this.isValidEventId(eventId)) {
      return false;
    }

    plan.reminderId = eventId;
    plan.notifyVersion = plan.version;
    return true;
  }
}
