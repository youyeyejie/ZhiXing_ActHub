import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { TodoEditorSheet } from './components/TodoEditorSheet';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';

class DemoTodoCardItem {
  id: string;
  title: string;
  subtitle: string;

  constructor(id: string, title: string, subtitle: string) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
  }
}

class UndoTodoTask {
  taskId: string;
  item: DemoTodoCardItem;
  originalIndex: number;

  constructor(taskId: string, item: DemoTodoCardItem, originalIndex: number) {
    this.taskId = taskId;
    this.item = item;
    this.originalIndex = originalIndex;
  }
}

/**
 * 待办模块主页骨架。
 * TODO: 后续接入搜索、分类管理和待办详情弹层。
 */
@ComponentV2
export struct TodoPage {
  @Local private app: AppState = useAppState();
  @Local private todoItems: Array<DemoTodoCardItem> = [
    new DemoTodoCardItem('todo_card_1', '待办测试卡片 #1', '左滑删除后可在通知中撤销'),
    new DemoTodoCardItem('todo_card_2', '待办测试卡片 #2', '每张卡片会生成独立撤销任务'),
    new DemoTodoCardItem('todo_card_3', '待办测试卡片 #3', '用于验证 InteractableCard 手势触发')
  ];
  @Local private undoTasks: Array<UndoTodoTask> = [];
  @Local private undoTaskSeq: number = 0;
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  private removeTodoById(todoId: string): void {
    let foundIndex: number = -1;
    for (let i = 0; i < this.todoItems.length; i++) {
      if (this.todoItems[i].id === todoId) {
        foundIndex = i;
        break;
      }
    }
    if (foundIndex < 0) {
      return;
    }

    const removedItem: DemoTodoCardItem = this.todoItems[foundIndex];
    const taskId: string = `todo_undo_${this.undoTaskSeq}`;
    this.undoTaskSeq = this.undoTaskSeq + 1;
    this.todoItems = this.todoItems.filter((item: DemoTodoCardItem) => {
      return item.id !== todoId;
    });
    this.undoTasks = [...this.undoTasks, new UndoTodoTask(taskId, removedItem, foundIndex)];
  }

  private findUndoTask(taskId: string): UndoTodoTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  private restoreTodoFromTask(taskId: string): void {
    const task: UndoTodoTask | null = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }

    const insertIndex: number = Math.max(0, Math.min(task.originalIndex, this.todoItems.length));
    const before: Array<DemoTodoCardItem> = this.todoItems.slice(0, insertIndex);
    const after: Array<DemoTodoCardItem> = this.todoItems.slice(insertIndex);
    this.todoItems = [...before, task.item, ...after];
  }

  private closeUndoTask(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: UndoTodoTask) => {
      return task.taskId !== taskId;
    });
  }

  @Builder
  private buildUndoStack() {
    Stack({ alignContent: Alignment.Bottom }) {
      ForEach(this.undoTasks, (task: UndoTodoTask, index: number) => {
        UndoNotification({
          message: `${task.item.title} 已删除`,
          actionText: '撤销',
          durationMs: 4000,
          onUndo: () => {
            this.restoreTodoFromTask(task.taskId);
          },
          onTimeout: () => {},
          onClose: () => {
            this.closeUndoTask(task.taskId);
          }
        })
          .id(task.taskId)
          .zIndex(this.undoTasks.length + 999 - index)
          .translate({ x: 0, y: -(this.undoTasks.length - 1 - index) * 14 })
          .opacity(Math.max(0.56, 1 - (this.undoTasks.length - 1 - index) * 0.12))
          .margin({ left: "4%", right: "28%", bottom: "6%" });
      }, (task: UndoTodoTask) => task.taskId);
    }
    .width('100%');
  }

  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
  }

  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  build() {
    MainTabPageLayout({
      title: '待办',
      actionIcon: $r('sys.symbol.magnifyingglass'),
      showFloatButton: true,
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索待办'));
      },
      onClickFloatingButton: () => {
        this.app.nav.openActionSheet();
      }
    }) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Text("此页面目前组件均为测试，需要修改！")
          CategoryFilter();

          PageScrollLayout({
            paddingBottom: 96
          }) {
            ForEach(this.todoItems, (item: DemoTodoCardItem) => {
              TodoCard({
                title: item.title,
                subtitle: item.subtitle,
                enableSwipeLeft: true,
                enableSwipeRight: false,
                onSwipeLeft: () => {
                  this.removeTodoById(item.id);
                },
                onSwipeRight: () => {},
                onCardTap: () => {}
              });
            }, (item: DemoTodoCardItem) => item.id);

            if (this.todoItems.length === 0) {
              Text('所有待办测试卡片已删除，可通过撤销通知逐个恢复。')
                .width('100%')
                .fontSize(12)
                .fontColor(this.app.theme.palette.textTertiary)
                .padding(12)
                .backgroundColor(this.app.theme.palette.surface)
                .borderRadius(12);
            }

            TodoEditorSheet();
          }
        }
        .width('100%')
        .height('100%');

        if (this.undoTasks.length > 0) {
          this.buildUndoStack();
        }
      }
      .layoutWeight(1)
      .width('100%');
    }
  }
}
