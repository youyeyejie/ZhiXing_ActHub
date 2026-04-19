import { UndoNotification } from "./UndoNotification";

/**
 * 组件功能简介：
 * - 撤销通知栈单项数据结构，统一承载页面级撤销提示所需字段。
 *
 * 可传入项：
 * - 构造参数包含任务 ID、提示文案、动作文案、持续时长与截止时间。
 *
 * 返回行为：
 * - 生成用于通知栈渲染与回调识别的数据对象。
 *
 * 副作用：
 * - 无。
 */
export class UndoStackItem {
  taskId: string;
  message: string;
  actionText: string;
  durationMs: number;
  deadlineMs: number;

  constructor(
    taskId: string,
    message: string,
    actionText: string = "撤销",
    durationMs: number = 5000,
    deadlineMs: number = Date.now() + Math.max(1000, durationMs),
  ) {
    this.taskId = taskId;
    this.message = message;
    this.actionText = actionText;
    this.durationMs = durationMs;
    this.deadlineMs = deadlineMs;
  }
}

/**
 * 组件功能简介：
 * - 通用撤销通知栈组件，负责多条撤销提示的叠放展示与事件分发。
 *
 * 可传入项：
 * - `tasks`：撤销任务列表。
 * - `onUndo`：点击撤销回调。
 * - `onTimeout`：超时回调。
 * - `onClose`：主动关闭回调。
 *
 * 返回行为：
 * - 渲染堆叠的撤销通知并按任务 ID 回传交互事件。
 *
 * 副作用：
 * - 会触发传入的事件回调。
 */
@ComponentV2
export struct UndoNotificationStack {
  @Param tasks: Array<UndoStackItem> = [];
  @Event onUndo: (taskId: string) => void = (_taskId: string) => {};
  @Event onTimeout: (taskId: string) => void = (_taskId: string) => {};
  @Event onClose: (taskId: string) => void = (_taskId: string) => {};

  build() {
    Column() {
      if (this.tasks.length > 0) {
        Stack({ alignContent: Alignment.Bottom }) {
          ForEach(
            this.tasks,
            (task: UndoStackItem, index: number) => {
              UndoNotification({
                message: task.message,
                actionText: task.actionText,
                durationMs: task.durationMs,
                deadlineMs: task.deadlineMs,
                onUndo: () => {
                  this.onUndo(task.taskId);
                },
                onTimeout: () => {
                  this.onTimeout(task.taskId);
                },
                onClose: () => {
                  this.onClose(task.taskId);
                },
              })
                .id(task.taskId)
                .zIndex(this.tasks.length + 1 - index)
                .translate({ x: 0, y: -(this.tasks.length - 1 - index) * 14 })
                .opacity(Math.max(0.56, 1 - (this.tasks.length - 1 - index) * 0.12))
                .margin({ left: "4%", right: "28%", bottom: "6%" });
            },
            (task: UndoStackItem) => task.taskId,
          )
        }.width("100%");
      }
    }.width("100%");
  }
}
