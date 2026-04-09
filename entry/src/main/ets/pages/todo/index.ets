import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { TodoEditorSheet } from './components/TodoEditorSheet';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';

/**
 * 待办卡片展示模型。
 * 当前仅用于页面内交互演示，不代表最终领域模型。
 */
class DemoTodoCardItem {
  id: string;
  title: string;
  subtitle: string;

  /**
   * @param id 卡片唯一标识
   * @param title 卡片标题
   * @param subtitle 卡片副标题
   */
  constructor(id: string, title: string, subtitle: string) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
  }
}

/**
 * 待办删除撤销任务。
 * 保存被删除元素和原始位置，用于限时恢复。
 */
class UndoTodoTask {
  taskId: string;
  item: DemoTodoCardItem;
  originalIndex: number;

  /**
   * @param taskId 撤销任务 ID
   * @param item 被删除的待办项
   * @param originalIndex 删除前的位置索引
   */
  constructor(taskId: string, item: DemoTodoCardItem, originalIndex: number) {
    this.taskId = taskId;
    this.item = item;
    this.originalIndex = originalIndex;
  }
}

/**
 * 组件功能简介：
 * - 待办模块主页，演示待办列表、左滑删除与撤销通知栈。
 * - TODO: 尚未接入真实仓储数据、分类管理与详情编辑流程。
 *
 * 可传入项：
 * - @Event onBottomBarVisibleChange: 通知父容器切换底部栏显隐。
 *
 * 返回行为：
 * - 返回主标签页布局并渲染待办列表与撤销通知层。
 *
 * 副作用：
 * - 会修改本地待办数组与撤销任务栈。
 * - 会通过 AppNav 打开搜索与 ActionSheet overlay。
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

  /**
   * 根据 ID 删除待办并生成可撤销任务。
   */
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

  /**
   * 按任务 ID 查找撤销任务。
   */
  private findUndoTask(taskId: string): UndoTodoTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  /**
   * 根据撤销任务恢复待办到原位置附近。
   */
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

  /**
   * 关闭撤销任务并从通知栈移除。
   */
  private closeUndoTask(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: UndoTodoTask) => {
      return task.taskId !== taskId;
    });
  }

  @Builder
  /**
   * 构建底部撤销通知堆叠。
   */
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

  /**
   * 页面进入时请求显示底部导航栏。
   */
  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
  }

  /**
   * 页面离开时保持底部导航栏可见。
   */
  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  /**
   * 渲染待办主页骨架与可撤销删除演示。
   * TODO: 当前仍以演示数据为主，后续接入真实仓储数据与详情流。
   */
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
