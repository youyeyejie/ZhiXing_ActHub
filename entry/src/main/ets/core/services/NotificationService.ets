/**
 * 类功能简介：
 * - 通知服务占位类，预留提醒注册与取消接口。
 * - TODO: 尚未接入权限申请与系统通知任务调度。
 *
 * 可传入项：
 * - 无（当前方法无参数）。
 *
 * 返回行为：
 * - 当前方法返回已完成 Promise 占位。
 *
 * 副作用：
 * - 当前无实际副作用。
 */
export class NotificationService {
  registerPlanReminder(): Promise<void> {
    // TODO: 注册日程提醒任务。
    return Promise.resolve();
  }

  cancelPlanReminder(): Promise<void> {
    // TODO: 取消日程提醒任务。
    return Promise.resolve();
  }
}
