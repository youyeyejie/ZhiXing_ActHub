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
 */
export class CalendarReminderService {
  private static readonly CALENDAR_NAME: string = 'ZhixingActHub';
  private static readonly CALENDAR_DISPLAY_NAME: string = '知行日程提醒';
  private static readonly REMINDER_MINUTES: number = 10;

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

  async syncPlanReminderRecord(plan: Plan): Promise<boolean> {
    const remindEnabled = this.normalizeReminderFlag(plan.enableRemind) === 1;
    const switchEnabled = await this.isPlanReminderSwitchEnabled();

    if (!remindEnabled || !switchEnabled || plan.startTime <= Date.now()) {
      return this.clearPlanReminderRecord(plan);
    }

    if (this.isValidEventId(plan.reminderId)) {
      const updated = await this.updatePlanEvent(plan);
      if (updated) {
        return false;
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
        return true;
      }
      return false;
    }

    const changed = plan.reminderId !== eventId;
    plan.reminderId = eventId;
    return changed;
  }

  async clearPlanReminderRecord(plan: Plan): Promise<boolean> {
    if (!this.isValidEventId(plan.reminderId)) {
      return false;
    }

    await this.deletePlanEvent(plan.reminderId);
    plan.reminderId = 0;
    return true;
  }

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
      const changed = await this.syncPlanReminderRecord(plan);
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
}
