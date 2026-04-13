import { UndoNotification } from "./UndoNotification";

/**
 * 撤销栈单项数据。
 * 统一承载页面级删除通知所需的最小字段。
 */
export class UndoStackItem {
  taskId: string;
  message: string;
  actionText: string;
  durationMs: number;

  constructor(taskId: string, message: string, actionText: string = "撤销", durationMs: number = 5000) {
    this.taskId = taskId;
    this.message = message;
    this.actionText = actionText;
    this.durationMs = durationMs;
  }
}

/**
 * 通用撤销通知栈。
 * 参考共享测试页的表现，统一多条通知的叠放位置和层级。
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
                .margin({ left: 16, right: 16, bottom: 16 });
            },
            (task: UndoStackItem) => task.taskId,
          )
        }
        .width("100%");
      }
    }
    .width("100%");
  }
}
