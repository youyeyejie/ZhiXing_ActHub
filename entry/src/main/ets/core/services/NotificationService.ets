import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { wantAgent } from '@kit.AbilityKit';
import { Plan } from '../models/Plan';
import { PlanRepository } from '../repositories/PlanRepository';
import { PreferenceStorage } from '../storage/PreferenceStorage';
import { AppPreferenceKey } from '../../app/AppConstants';

const TAG: string = '[NotificationService]';
const DOMAIN_NUMBER: number = 0xFF00;

/**
 * 类功能简介：
 * - 系统通知服务封装
 * - 提供专注阶段通知与日程提醒通知能力
 * - 支持点击通知拉起应用
 */
export class NotificationService {
  private static readonly FOCUS_NOTIFICATION_ID: number = 1001;
  private static readonly PLAN_NOTIFICATION_ID_BASE: number = 200000;
  private static readonly PLAN_REMINDER_ADVANCE_MS: number = 10 * 60 * 1000;
  private static readonly DAY_MS: number = 24 * 60 * 60 * 1000;
  private static readonly ENTRY_BUNDLE_NAME: string = 'com.nis3366.ZhixingActhub';
  private static readonly ENTRY_ABILITY_NAME: string = 'EntryAbility';
  private static planReminderTimers: Map<string, number> = new Map<string, number>();
  private static sentPlanReminderKeys: Set<string> = new Set<string>();

  private planRepository: PlanRepository = new PlanRepository();
  private preferenceStorage: PreferenceStorage = PreferenceStorage.getInstance();

  private safeTrim(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private toDayStart(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const minute = date.getMinutes();
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  private buildPlanReminderContent(plan: Plan): string {
    const title = this.safeTrim(plan.content);
    const displayTitle = title.length > 0 ? title : '未命名日程';
    return `${displayTitle} 将于 ${this.formatHourMinute(plan.startTime)} 开始`;
  }

  private buildPlanReminderKey(planId: string, reminderTimestamp: number): string {
    return `${planId}#${reminderTimestamp}`;
  }

  private resolvePlanNotificationId(planId: string, reminderTimestamp: number): number {
    const source = `${planId}_${reminderTimestamp}`;
    let hash = 0;
    for (let i = 0; i < source.length; i++) {
      hash = (hash * 31 + source.charCodeAt(i)) % 1_000_000;
    }
    return NotificationService.PLAN_NOTIFICATION_ID_BASE + hash;
  }

  private static clearAllPlanReminderTimers(): void {
    NotificationService.planReminderTimers.forEach((timerId: number) => {
      clearTimeout(timerId);
    });
    NotificationService.planReminderTimers.clear();
  }

  private static markReminderSent(reminderKey: string): void {
    NotificationService.sentPlanReminderKeys.add(reminderKey);
  }

  private static hasReminderBeenSent(reminderKey: string): boolean {
    return NotificationService.sentPlanReminderKeys.has(reminderKey);
  }

  private static pruneSentReminderKeys(currentDayStart: number): void {
    const keepFrom = currentDayStart - NotificationService.DAY_MS;
    const deletingKeys: Array<string> = [];
    NotificationService.sentPlanReminderKeys.forEach((key: string) => {
      const sep = key.lastIndexOf('#');
      if (sep < 0) {
        deletingKeys.push(key);
        return;
      }
      const timestampText = key.substring(sep + 1);
      const timestamp = Number(timestampText);
      if (timestamp !== timestamp || timestamp < keepFrom) {
        deletingKeys.push(key);
      }
    });
    for (let i = 0; i < deletingKeys.length; i++) {
      NotificationService.sentPlanReminderKeys.delete(deletingKeys[i]);
    }
  }

  private triggerPlanReminderOnce(notificationId: number, reminderKey: string, content: string): void {
    if (NotificationService.hasReminderBeenSent(reminderKey)) {
      return;
    }
    NotificationService.markReminderSent(reminderKey);
    NotificationService.publishNotificationById(
      notificationId,
      '日程即将开始',
      content
    );
  }

  private static async publishNotificationById(
    notificationId: number,
    title: string,
    content: string
  ): Promise<void> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: NotificationService.ENTRY_BUNDLE_NAME,
          abilityName: NotificationService.ENTRY_ABILITY_NAME,
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    try {
      const wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);
      const notificationRequest: notificationManager.NotificationRequest = {
        id: notificationId,
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content
          }
        },
        wantAgent: wantAgentObj
      };

      await new Promise<void>((resolve) => {
        notificationManager.publish(notificationRequest, (err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN_NUMBER, TAG, `发布通知失败. Code: ${err.code}, message: ${err.message}`);
            resolve();
            return;
          }
          hilog.info(DOMAIN_NUMBER, TAG, `成功发布通知: [${title}]`);
          resolve();
        });
      });
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `发布通知异常: ${JSON.stringify(error)}`);
    }
  }

  private static async cancelNotificationById(notificationId: number): Promise<void> {
    await new Promise<void>((resolve) => {
      notificationManager.cancel(notificationId, (err: BusinessError) => {
        if (err) {
          hilog.warn(DOMAIN_NUMBER, TAG, `取消通知失败或通知不存在. Code: ${err.code}`);
          resolve();
          return;
        }
        resolve();
      });
    });
  }

  private rebuildTodayPlanReminderTimers(plans: Array<Plan>): void {
    NotificationService.clearAllPlanReminderTimers();
    const now = Date.now();
    const dayStart = this.toDayStart(now);
    const dayEnd = dayStart + NotificationService.DAY_MS;
    NotificationService.pruneSentReminderKeys(dayStart);

    for (let i = 0; i < plans.length; i++) {
      const plan = plans[i];
      const planId = this.safeTrim(plan.id);
      if (planId.length === 0) {
        continue;
      }
      const startTime = plan.startTime;
      if (startTime < dayStart || startTime >= dayEnd) {
        continue;
      }
      const reminderTimestamp = startTime - NotificationService.PLAN_REMINDER_ADVANCE_MS;
      const reminderKey = this.buildPlanReminderKey(planId, reminderTimestamp);
      const notificationId = this.resolvePlanNotificationId(planId, reminderTimestamp);
      const content = this.buildPlanReminderContent(plan);
      if (reminderTimestamp <= now) {
        if (startTime > now) {
          this.triggerPlanReminderOnce(notificationId, reminderKey, content);
        }
        continue;
      }

      const delayMs = reminderTimestamp - now;
      const timerId = setTimeout((): void => {
        NotificationService.planReminderTimers.delete(reminderKey);
        this.triggerPlanReminderOnce(notificationId, reminderKey, content);
      }, delayMs);
      NotificationService.planReminderTimers.set(reminderKey, timerId);
    }
  }

  private isPlanReminderEnabled(): boolean {
    return this.preferenceStorage.getBooleanSync(AppPreferenceKey.PLAN_REMINDER_ENABLED, false);
  }

  /**
   * 发送专注模块专属的完成通知，点击通知回到app
   * @param title 通知标题
   * @param content 通知内容
   */
  static async sendNotification(title: string, content: string): Promise<void> {
    await NotificationService.publishNotificationById(
      NotificationService.FOCUS_NOTIFICATION_ID,
      title,
      content
    );
  }

  /**
   * 取消专注通知（预留：比如用户手动提前中断了专注，可以清理掉通知栏的提示）
   */
  static cancelFocusNotification(): void {
    NotificationService.cancelNotificationById(NotificationService.FOCUS_NOTIFICATION_ID);
  }

  async registerPlanReminder(): Promise<void> {
    try {
      if (!this.isPlanReminderEnabled()) {
        await this.cancelPlanReminder();
        return;
      }
      const plans = await this.planRepository.findAll();
      this.rebuildTodayPlanReminderTimers(plans);
    } catch (error) {
      NotificationService.clearAllPlanReminderTimers();
      hilog.warn(DOMAIN_NUMBER, TAG, `重建日程提醒失败: ${JSON.stringify(error)}`);
    }
  }

  async cancelPlanReminder(): Promise<void> {
    NotificationService.clearAllPlanReminderTimers();
  }
}
