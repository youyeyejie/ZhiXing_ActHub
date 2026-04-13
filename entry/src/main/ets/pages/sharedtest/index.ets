import { InteractableCard } from '../../components/card/InteractableCard';
import { AutoSaveText } from '../../components/form/AutoSaveText';
import { EditableSuite } from '../../components/form/EditableSuite';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { ThemeMode } from '../../core/theme/ThemeManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppDatabase } from '../../core/database/AppDatabase';
import { Todo } from '../../core/models/Todo';
import { TodoRepository } from '../../core/repositories/TodoRepository';
import { TodoTestDataHelper } from '../../core/services/TodoTestDataHelper';
import promptAction from '@ohos.promptAction';

const SHARED_TEST_LOG_DOMAIN: number = 0x0000;
const SHARED_TEST_LOG_TAG: string = 'SharedTestPage';

class DemoInteractableItem {
  id: string;
  title: string;
  subtitle: string;

  /**
   * @param id 卡片唯一标识
   * @param title 卡片标题
   * @param subtitle 卡片描述
   */
  constructor(id: string, title: string, subtitle: string) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
  }
}

class UndoDeleteTask {
  taskId: string;
  item: DemoInteractableItem;
  originalIndex: number;

  /**
   * @param taskId 撤销任务 ID
   * @param item 被删除的卡片项
   * @param originalIndex 删除前索引
   */
  constructor(taskId: string, item: DemoInteractableItem, originalIndex: number) {
    this.taskId = taskId;
    this.item = item;
    this.originalIndex = originalIndex;
  }
}

/**
 * 组件功能简介：
 * - 通用交互抽象层测试页面，用于集中验证卡片、弹层、自动保存与仓储测试流程。
 *
 * 返回行为：
 * - 返回可滚动测试页，按状态渲染撤销通知。
 *
 * 副作用：
 * - 会更新本地日志、卡片数据与撤销任务栈。
 * - 会调用仓储执行 CRUD 测试并写入日志。
 * - 会通过 AppNav 触发搜索 overlay 路由。
 */
@ComponentV2
export struct SharedInteractionTestPage {
  @Local private app: AppState = useAppState();
  @Local private keyboardOffset: number = 0;
  @Local private progress: number = 0.45;
  @Local private logs: string[] = [];
  @Local private cardItems: Array<DemoInteractableItem> = [
    new DemoInteractableItem('card_1', '交互卡片 #1', '左滑删除后可在通知中撤销'),
    new DemoInteractableItem('card_2', '交互卡片 #2', '每张卡片都会生成独立撤销任务'),
    new DemoInteractableItem('card_3', '交互卡片 #3', '超时不撤销则执行 onTimeout 逻辑')
  ];
  @Local private undoTasks: Array<UndoDeleteTask> = [];
  @Local private undoTaskSeq: number = 0;
  private todoRepository: TodoRepository = new TodoRepository();
  private todoTestDataHelper: TodoTestDataHelper = new TodoTestDataHelper();

  private logToConsole(message: string): void {
    hilog.info(SHARED_TEST_LOG_DOMAIN, SHARED_TEST_LOG_TAG, '%{public}s', message);
  }

  private removeCardById(cardId: string): void {
    let foundIndex: number = -1;
    for (let i = 0; i < this.cardItems.length; i++) {
      if (this.cardItems[i].id === cardId) {
        foundIndex = i;
        break;
      }
    }
    if (foundIndex < 0) {
      return;
    }

    const removedItem: DemoInteractableItem = this.cardItems[foundIndex];
    const taskId: string = `undo_task_${this.undoTaskSeq}`;
    this.undoTaskSeq = this.undoTaskSeq + 1;
    this.cardItems = this.cardItems.filter((item: DemoInteractableItem) => {
      return item.id !== cardId;
    });
    this.undoTasks = [...this.undoTasks, new UndoDeleteTask(taskId, removedItem, foundIndex)];
    this.logs.push(`${removedItem.title} 左滑删除，等待撤销`);
  }

  private findUndoTask(taskId: string): UndoDeleteTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  private restoreCardFromTask(taskId: string): void {
    const task: UndoDeleteTask | null = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    const insertIndex: number = Math.max(0, Math.min(task.originalIndex, this.cardItems.length));
    const before: Array<DemoInteractableItem> = this.cardItems.slice(0, insertIndex);
    const after: Array<DemoInteractableItem> = this.cardItems.slice(insertIndex);
    this.cardItems = [...before, task.item, ...after];
    this.logs.push(`${task.item.title} 已撤销恢复`);
  }

  private closeUndoTask(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: UndoDeleteTask) => {
      return task.taskId !== taskId;
    });
  }

  @Builder
  private buildUndoStack() {
    Stack({ alignContent: Alignment.Bottom }) {
      ForEach(this.undoTasks, (task: UndoDeleteTask, index: number) => {
        UndoNotification({
          message: `${task.item.title} 已删除`,
          actionText: '撤销',
          durationMs: 4000,
          onUndo: () => {
            this.restoreCardFromTask(task.taskId);
          },
          onTimeout: () => {
            this.logs.push(task.item.title + ' 删除已生效');
          },
          onClose: () => {
            this.closeUndoTask(task.taskId);
          }
        })
          .id(task.taskId)
          .zIndex(this.undoTasks.length + 1 - index)
          .translate({ x: 0, y: -(this.undoTasks.length - 1 - index) * 14 })
          .opacity(Math.max(0.56, 1 - (this.undoTasks.length - 1 - index) * 0.12))
          .margin({ left: 16, right: 16, bottom: 16 });
      }, (task: UndoDeleteTask) => task.taskId);
    }
    .width('100%');
  }

  private formatTodo(todo: Todo | null): string {
    if (todo === null) {
      return 'null';
    }
    return `id=${todo.id}, content=${todo.content}, isDone=${todo.isDone}, updatedAt=${todo.updatedAt}`;
  }

  private async runTodoRepositoryCrudTest(): Promise<void> {
    if (!AppDatabase.getInstance().isReady()) {
      const notReadyMessage: string = 'TodoRepository CRUD 测试中止: 数据库尚未初始化';
      this.logs.push(notReadyMessage);
      hilog.error(SHARED_TEST_LOG_DOMAIN, SHARED_TEST_LOG_TAG, '%{public}s', notReadyMessage);
      return;
    }

    const now: number = Date.now();
    const todoId: string = `shared_test_todo_${now}`;
    const todo: Todo = new Todo();
    todo.id = todoId;
    todo.content = `SharedTest Todo ${now}`;
    todo.timestamp = now;
    todo.createdAt = now;
    todo.updatedAt = now;

    const startMessage: string = `开始执行 TodoRepository CRUD 测试: ${todoId}`;
    this.logs.push(startMessage);
    this.logToConsole(startMessage);

    try {
      await this.todoRepository.save(todo);
      const persistedId: string = todo.id;
      const createMessage: string = `Create 成功: ${this.formatTodo(todo)}`;
      this.logs.push(createMessage);
      this.logToConsole(createMessage);

      const createdTodo: Todo | null = await this.todoRepository.findById(persistedId);
      const readMessage: string = `Read 成功: ${this.formatTodo(createdTodo)}`;
      this.logs.push(readMessage);
      this.logToConsole(readMessage);
      if (createdTodo === null) {
        throw new Error('Create 后 findById 返回 null');
      }

      createdTodo.content = `${createdTodo.content} (updated)`;
      createdTodo.isDone = 1;
      createdTodo.updatedAt = Date.now();
      await this.todoRepository.save(createdTodo);
      const updateMessage: string = `Update 成功: ${this.formatTodo(createdTodo)}`;
      this.logs.push(updateMessage);
      this.logToConsole(updateMessage);

      const allTodos: Array<Todo> = await this.todoRepository.findAll();
      const listMessage: string = `List 成功: 当前 Todo 总数 = ${allTodos.length}`;
      this.logs.push(listMessage);
      this.logToConsole(listMessage);

      await this.todoRepository.removeById(persistedId);
      const deletedTodo: Todo | null = await this.todoRepository.findById(persistedId);
      const deleteMessage: string = `Delete 成功: 删除后查询结果 = ${this.formatTodo(deletedTodo)}`;
      this.logs.push(deleteMessage);
      this.logToConsole(deleteMessage);
    } catch (err) {
      const errorMessage: string = `TodoRepository CRUD 测试失败: ${JSON.stringify(err)}`;
      this.logs.push(errorMessage);
      hilog.error(SHARED_TEST_LOG_DOMAIN, SHARED_TEST_LOG_TAG, '%{public}s', errorMessage);
    }
  }

  private async generateTodoTestData(): Promise<void> {
    const inserted = await this.todoTestDataHelper.generateFocusTestData(10);
    const message = `TodoTestDataHelper 生成完成，新增 ${inserted} 条测试待办`;
    this.logs.push(message);
    this.logToConsole(message);
  }

  @Builder
  private buildActionSheetContent() {
    Column({ space: 12 }) {
      Text('ActionSheet 内容测试')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);

      EditableSuite({
        title: '动作编辑套件',
        onSaveField: (field: string, value: string) => {
          this.logs.push('EditableSuite 已保存字段: ' + field + ' = ' + value);
        }
      });

      Button('关闭弹层')
        .width('100%')
        .height(42)
        .onClick(() => {
          this.app.nav.back(false);
        });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private buildDetailDialogContent() {
    Column({ space: 10 }) {
      Text('详情卡片基础组件')
        .fontSize(18)
        .fontWeight(FontWeight.Bold);
      Text('宽度 80%，高度 60%，支持背景遮罩和右上角关闭。')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);
      Text('你可以在这里放详情展示、编辑表单或操作按钮。')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: 16 }) {
          Text('通用交互层测试')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary);

          Text('用于验证卡片手势、弹层、自动保存、撤销通知、搜索遮罩和圆环绘制。')
            .fontSize(13)
            .fontColor(this.app.theme.palette.textSecondary);

          Row({ space: 8 }) {
            Button('浅色')
              .fontSize(12)
              .fontColor(this.app.theme.palette.surface)
              .backgroundColor(this.app.theme.palette.primary)
              .onClick(() => {
                this.app.theme.set(ThemeMode.LIGHT);
                this.logs.push('主题切换: LIGHT');
              });

            Button('深色')
              .fontSize(12)
              .fontColor(this.app.theme.palette.surface)
              .backgroundColor(this.app.theme.palette.primary)
              .onClick(() => {
                this.app.theme.set(ThemeMode.DARK);
                this.logs.push('主题切换: DARK');
              });
          }
          .width('100%');

          ForEach(this.cardItems, (item: DemoInteractableItem) => {
            InteractableCard({
              leftHint: '左滑: 删除',
              rightHint: '右滑: 启动专注',
              enableSwipeLeft: true,
              enableSwipeRight: false,
              onSwipeLeft: () => {
                this.removeCardById(item.id);
              },
              onSwipeRight: () => {
                this.logs.push(item.title + ' 右滑触发');
              },
              onCardTap: () => {
                this.app.nav.openDetailCard(this.buildDetailDialogContent, '详情预览');
                this.logs.push(item.title + ' 点击打开详情卡片');
              }
            }) {
              Column({ space: 8 }) {
                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium);
                Text(item.subtitle)
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textSecondary);
              }
              .alignItems(HorizontalAlign.Start);
            }
          }, (item: DemoInteractableItem) => item.id);

          if (this.cardItems.length === 0) {
            Text('所有交互卡片均已删除，可通过撤销通知逐个恢复。')
              .width('100%')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textTertiary)
              .padding(12)
              .backgroundColor(this.app.theme.palette.surface)
              .borderRadius(12);
          }

          Row({ space: 14 }) {
            Button('sheet')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.app.nav.openActionSheet(this.buildActionSheetContent);
                this.logs.push('ActionSheet 打开');
              });

            Button('search')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索测试页'));
                this.logs.push('Search overlay route 打开');
              });

            Button('detail')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.app.nav.openDetailCard(this.buildDetailDialogContent, '详情预览');
                this.logs.push('通过 DetailCard 组件打开详情卡片');
              });

            Button('toast')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.getUIContext().getPromptAction().showToast({
                  message: '这是一个通过 UIContext 调用的提示框。',
                  duration: 2000,
                  showMode: promptAction.ToastShowMode.DEFAULT,
                  bottom: 80
                })
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween);

          AutoSaveText({
            label: 'AutoSaveText 单组件测试',
            placeholder: '停止输入后自动保存',
            onAutoSave: (value: string) => {
              this.logs.push('AutoSaveText 自动保存: ' + value);
            }
          });

          Button('测试 TodoRepository CRUD')
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor(this.app.theme.palette.surface)
            .backgroundColor(this.app.theme.palette.primary)
            .onClick(() => {
              this.runTodoRepositoryCrudTest();
            });

          Button('生成 Focus 测试待办（TodoTestDataHelper）')
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor(this.app.theme.palette.surface)
            .backgroundColor(this.app.theme.palette.primary)
            .onClick(() => {
              this.generateTodoTestData();
            });

          Column({ space: 8 }) {
            Text('最近日志')
              .fontSize(14)
              .fontWeight(FontWeight.Medium);

            ForEach(this.logs, (item: string) => {
              Text('- ' + item)
                .fontSize(12)
                .fontColor(this.app.theme.palette.textSecondary)
                .width('100%');
            });

            if (this.logs.length === 0) {
              Text('暂无交互日志')
                .fontSize(12)
                .fontColor(this.app.theme.palette.textTertiary);
            }
          }
          .width('100%')
          .padding(12)
          .borderRadius(14)
          .backgroundColor(this.app.theme.palette.surface);

        }
        .alignItems(HorizontalAlign.Start)
        .padding(20);
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background);

      if (this.undoTasks.length > 0) {
        this.buildUndoStack();
      }
    }
    .width('100%')
    .height('100%');
  }
}

@Builder
export function SharedInteractionTestPageBuilder(_name: string, _param: Object) {
  SharedInteractionTestPage();
}
