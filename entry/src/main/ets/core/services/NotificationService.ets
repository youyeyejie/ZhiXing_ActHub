import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, wantAgent } from '@kit.AbilityKit';
import { AppPreferenceKey } from '../../app/AppConstants';
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';

const NOTIFICATION_PERMISSION_REFUSED_CODE: number = 1600004;

/**
 * 类功能简介：
 * - 系统通知服务封装。
 * - 当前仅承载专注模块完成通知，日程提醒已改由 Calendar Kit 承载。
 */
export class NotificationService {
  private static readonly FOCUS_NOTIFICATION_ID: number = 1001;
  private static readonly ENTRY_BUNDLE_NAME: string = 'com.nis3366.ZhixingActhub';
  private static readonly ENTRY_ABILITY_NAME: string = 'EntryAbility';
  private static readonly userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();

  static async isNotificationPermissionEnabled(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (_err) {
      return false;
    }
  }

  static async requestNotificationPermission(context: common.UIAbilityContext): Promise<boolean> {
    const enabled = await NotificationService.isNotificationPermissionEnabled();
    if (enabled) {
      return true;
    }

    try {
      await notificationManager.requestEnableNotification(context);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      if (error.code === NOTIFICATION_PERMISSION_REFUSED_CODE) {
        return false;
      }
      return false;
    }
  }

  static async isFocusNotificationEnabled(): Promise<boolean> {
    try {
      return await NotificationService.userPreferenceRepository.getBoolean(
        AppPreferenceKey.NOTIFICATION_ENABLED,
        true,
      );
    } catch (_err) {
      return true;
    }
  }

  static async sendNotification(title: string, content: string): Promise<void> {
    if (!(await NotificationService.isFocusNotificationEnabled())) {
      return;
    }

    if (!(await NotificationService.isNotificationPermissionEnabled())) {
      return;
    }

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

      notificationManager.publish(notificationRequest, (_err: BusinessError) => {});
    } catch (_error) {}
  }

  static cancelFocusNotification(): void {
    notificationManager.cancel(NotificationService.FOCUS_NOTIFICATION_ID, (_err: BusinessError) => {});
  }
}
