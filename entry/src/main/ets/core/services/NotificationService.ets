import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { wantAgent } from '@kit.AbilityKit'; // <-- 新增引入 wantAgent

const TAG: string = '[NotificationService]';
const DOMAIN_NUMBER: number = 0xFF00;

/**
 * 类功能简介：
 * - 系统通知服务封装
 * - 提供发送专注完成、休息完成等系统级通知的能力
 * - 支持点击通知拉起应用
 */
export class NotificationService {
  // 定义专属的通知ID。使用固定ID可以确保新的通知会覆盖旧的通知，避免通知栏堆积
  private static readonly FOCUS_NOTIFICATION_ID: number = 1001;

  /**
   * 发送专注模块专属的完成通知，点击通知回到app
   * @param title 通知标题
   * @param content 通知内容
   */
  static async sendNotification(title: string, content: string): Promise<void> {
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
    // TODO: 注册日程提醒任务。
    return Promise.resolve();
  }

  cancelPlanReminder(): Promise<void> {
    // TODO: 取消日程提醒任务。
    return Promise.resolve();
  }
}