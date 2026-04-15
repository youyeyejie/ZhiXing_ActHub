import { notificationManager } from '@kit.NotificationKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, wantAgent } from '@kit.AbilityKit';
import { AppPreferenceKey } from '../../app/AppConstants';
import { Plan } from '../models/Plan';
import { PlanRepository } from '../repositories/PlanRepository';
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';

const TAG: string = '[NotificationService]';
const DOMAIN_NUMBER: number = 0xFF00;
const NOTIFICATION_PERMISSION_REFUSED_CODE: number = 1600004;

/**
 * 类功能简介：
 * - 系统通知服务封装
 * - 提供发送专注完成、休息完成等系统级通知的能力
 * - 支持点击通知拉起应用
 */
export class NotificationService {
  // 定义专属的通知ID。使用固定ID可以确保新的通知会覆盖旧的通知，避免通知栏堆积
  private static readonly FOCUS_NOTIFICATION_ID: number = 1001;
  private static readonly PLAN_REMINDER_OFFSET_MINUTES: number = 20;
  private static readonly PLAN_REMINDER_RING_DURATION_SECONDS: number = 60;
  private static readonly userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();
  private static readonly planRepository: PlanRepository = new PlanRepository();

  private static normalizeReminderFlag(value: number): number {
    return value === 1 ? 1 : 0;
  }

  private static buildPlanReminderTitle(plan: Plan): string {
    const content = `${plan.content}`.trim();
    return content.length > 0 ? content : '日程提醒';
  }

  private static buildPlanReminderContent(plan: Plan): string {
    const content = `${plan.content}`.trim();
    if (content.length > 0) {
      return `即将开始：${content}`;
    }
    return '你有一个日程将在 20 分钟后开始';
  }

  private static resolvePlanReminderTime(plan: Plan): number {
    return plan.startTime - NotificationService.PLAN_REMINDER_OFFSET_MINUTES * 60 * 1000;
  }

  private static async isPlanReminderSwitchEnabled(): Promise<boolean> {
    try {
      return await NotificationService.userPreferenceRepository.getBoolean(
        AppPreferenceKey.PLAN_REMINDER_ENABLED,
        false,
      );
    } catch (err) {
      hilog.warn(DOMAIN_NUMBER, TAG, `读取日程提醒总开关失败. ${JSON.stringify(err)}`);
      return false;
    }
  }

  private static async cancelAgentReminder(reminderId: number): Promise<void> {
    if (reminderId <= 0) {
      return;
    }
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      hilog.info(DOMAIN_NUMBER, TAG, `取消代理提醒成功: ${reminderId}`);
    } catch (err) {
      hilog.warn(DOMAIN_NUMBER, TAG, `取消代理提醒失败: ${reminderId}, ${JSON.stringify(err)}`);
    }
  }

  private static buildPlanReminderRequest(plan: Plan): reminderAgentManager.ReminderRequestCalendar {
    const reminderTime = new Date(NotificationService.resolvePlanReminderTime(plan));
    return {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: reminderTime.getFullYear(),
        month: reminderTime.getMonth() + 1,
        day: reminderTime.getDate(),
        hour: reminderTime.getHours(),
        minute: reminderTime.getMinutes(),
      },
      actionButton: [
        {
          title: '关闭提醒',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
        }
      ],
      wantAgent: {
        pkgName: 'com.nis3366.ZhixingActhub',
        abilityName: 'EntryAbility',
      },
      ringDuration: NotificationService.PLAN_REMINDER_RING_DURATION_SECONDS,
      title: NotificationService.buildPlanReminderTitle(plan),
      content: NotificationService.buildPlanReminderContent(plan),
      slotType: notificationManager.SlotType.CONTENT_INFORMATION,
    };
  }

  static async syncPlanReminderRecord(plan: Plan): Promise<boolean> {
    const remindEnabled = NotificationService.normalizeReminderFlag(plan.enableRemind) === 1;
    const switchEnabled = await NotificationService.isPlanReminderSwitchEnabled();

    if (!remindEnabled || !switchEnabled) {
      if (plan.reminderId > 0) {
        await NotificationService.cancelAgentReminder(plan.reminderId);
        plan.reminderId = 0;
        return true;
      }
      return false;
    }

    if (!(await NotificationService.canSendNotification())) {
      if (plan.reminderId > 0) {
        await NotificationService.cancelAgentReminder(plan.reminderId);
        plan.reminderId = 0;
        return true;
      }
      return false;
    }

    const triggerTime = NotificationService.resolvePlanReminderTime(plan);
    if (triggerTime <= Date.now()) {
      hilog.warn(DOMAIN_NUMBER, TAG, `日程提醒时间已过，跳过注册. planId=${plan.id}`);
      if (plan.reminderId > 0) {
        await NotificationService.cancelAgentReminder(plan.reminderId);
        plan.reminderId = 0;
        return true;
      }
      return false;
    }

    if (plan.reminderId > 0) {
      await NotificationService.cancelAgentReminder(plan.reminderId);
    }

    try {
      const reminderId = await reminderAgentManager.publishReminder(
        NotificationService.buildPlanReminderRequest(plan),
      );
      hilog.info(DOMAIN_NUMBER, TAG, `注册日程代理提醒成功. planId=${plan.id}, reminderId=${reminderId}`);
      const changed = plan.reminderId !== reminderId;
      plan.reminderId = reminderId;
      return changed;
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `注册日程代理提醒失败. planId=${plan.id}, ${JSON.stringify(err)}`);
      if (plan.reminderId !== 0) {
        plan.reminderId = 0;
        return true;
      }
      return false;
    }
  }

  static async clearPlanReminderRecord(plan: Plan): Promise<boolean> {
    if (plan.reminderId <= 0) {
      return false;
    }
    await NotificationService.cancelAgentReminder(plan.reminderId);
    plan.reminderId = 0;
    return true;
  }

  private static async isNotificationSwitchEnabled(): Promise<boolean> {
    try {
      const storedValue = await NotificationService.userPreferenceRepository.getString(
        AppPreferenceKey.NOTIFICATION_ENABLED,
      );
      if (storedValue.length > 0) {
        const enabled = storedValue === '1';
        hilog.info(DOMAIN_NUMBER, TAG, `通知总开关状态: ${enabled}`);
        return enabled;
      }

      const permissionEnabled = await NotificationService.isNotificationPermissionEnabled();
      await NotificationService.userPreferenceRepository.setBoolean(
        AppPreferenceKey.NOTIFICATION_ENABLED,
        permissionEnabled,
      );
      hilog.info(DOMAIN_NUMBER, TAG, `通知总开关缺失，按系统权限初始化: ${permissionEnabled}`);
      return permissionEnabled;
    } catch (err) {
      hilog.warn(DOMAIN_NUMBER, TAG, `读取通知总开关失败，回退为关闭. ${JSON.stringify(err)}`);
      return false;
    }
  }

  static async canSendNotification(): Promise<boolean> {
    const switchEnabled = await NotificationService.isNotificationSwitchEnabled();
    if (!switchEnabled) {
      hilog.info(DOMAIN_NUMBER, TAG, '通知总开关已关闭，跳过通知发送');
      return false;
    }

    const permissionEnabled = await NotificationService.isNotificationPermissionEnabled();
    if (!permissionEnabled) {
      hilog.warn(DOMAIN_NUMBER, TAG, '系统通知权限未开启，跳过通知发送');
      return false;
    }
    return true;
  }

  /**
   * 查询当前应用是否已获得系统通知授权。
   */
  static async isNotificationPermissionEnabled(): Promise<boolean> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      hilog.info(DOMAIN_NUMBER, TAG, `通知权限状态: ${enabled}`);
      return enabled;
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(
        DOMAIN_NUMBER,
        TAG,
        `查询通知权限失败. Code: ${error.code}, message: ${error.message}`,
      );
      return false;
    }
  }

  /**
   * 向用户申请系统通知授权。
   * - 已授权时直接返回 true
   * - 首次申请成功时返回 true
   * - 用户拒绝或申请失败时返回 false
   */
  static async requestNotificationPermission(context: common.UIAbilityContext): Promise<boolean> {
    const enabled = await NotificationService.isNotificationPermissionEnabled();
    if (enabled) {
      return true;
    }

    try {
      await notificationManager.requestEnableNotification(context);
      hilog.info(DOMAIN_NUMBER, TAG, '请求通知权限成功');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      if (error.code === NOTIFICATION_PERMISSION_REFUSED_CODE) {
        hilog.warn(
          DOMAIN_NUMBER,
          TAG,
          `用户拒绝通知权限申请. Code: ${error.code}, message: ${error.message}`,
        );
        return false;
      }

      hilog.error(
        DOMAIN_NUMBER,
        TAG,
        `请求通知权限失败. Code: ${error.code}, message: ${error.message}`,
      );
      return false;
    }
  }

  /**
   * 发送专注模块专属的完成通知，点击通知回到app
   * @param title 通知标题
   * @param content 通知内容
   */
  static async sendNotification(title: string, content: string): Promise<void> {
    if (!(await NotificationService.canSendNotification())) {
      return;
    }

    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.nis3366.ZhixingActhub', 
          abilityName: 'EntryAbility',
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    try {
      const wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);
      let notificationRequest: notificationManager.NotificationRequest = {
        id: NotificationService.FOCUS_NOTIFICATION_ID,
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

      // 发布通知
      notificationManager.publish(notificationRequest, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN_NUMBER, TAG, `发布通知失败. Code: ${err.code}, message: ${err.message}`);
          return;
        }
        hilog.info(DOMAIN_NUMBER, TAG, `成功发布通知: [${title}]`);
      });

    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `获取 WantAgent 失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 取消专注通知（预留：比如用户手动提前中断了专注，可以清理掉通知栏的提示）
   */
  static cancelFocusNotification(): void {
    notificationManager.cancel(NotificationService.FOCUS_NOTIFICATION_ID, (err: BusinessError) => {
      if (err) {
        hilog.warn(DOMAIN_NUMBER, TAG, `取消通知失败或通知不存在. Code: ${err.code}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, '成功取消专注通知');
    });
  }

  registerPlanReminder(): Promise<void> {
    return NotificationService.isPlanReminderSwitchEnabled().then(async (switchEnabled: boolean) => {
      if (!switchEnabled) {
        hilog.info(DOMAIN_NUMBER, TAG, '日程提醒总开关关闭，跳过重建提醒');
        return;
      }
      const plans = await NotificationService.planRepository.findAll();
      for (let i = 0; i < plans.length; i++) {
        const plan = plans[i];
        if (NotificationService.normalizeReminderFlag(plan.enableRemind) !== 1) {
          continue;
        }
        const changed = await NotificationService.syncPlanReminderRecord(plan);
        if (changed) {
          await NotificationService.planRepository.save(plan);
        }
      }
    });
  }

  cancelPlanReminder(): Promise<void> {
    return NotificationService.planRepository.findAll().then(async (plans: Array<Plan>) => {
      for (let i = 0; i < plans.length; i++) {
        const plan = plans[i];
        const changed = await NotificationService.clearPlanReminderRecord(plan);
        if (changed) {
          await NotificationService.planRepository.save(plan);
        }
      }
    });
  }
}
