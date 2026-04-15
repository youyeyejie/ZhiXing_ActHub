import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, wantAgent } from '@kit.AbilityKit';
import { AppPreferenceKey } from '../../app/AppConstants';
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
  private static readonly userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();

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
    return NotificationService.canSendNotification().then((enabled: boolean) => {
      if (!enabled) {
        hilog.info(DOMAIN_NUMBER, TAG, '跳过注册日程提醒任务');
        return;
      }
      // TODO: 注册日程提醒任务。
    });
  }

  cancelPlanReminder(): Promise<void> {
    // TODO: 取消日程提醒任务。
    return Promise.resolve();
  }
}
