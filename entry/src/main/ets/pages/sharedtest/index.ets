import { InteractableCard } from '../../components/card/InteractableCard';
import { DetailCard, DetailCardController } from '../../components/card/DetailCard';
import { ActionSheet, ActionSheetController } from '../../components/card/ActionSheet';
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

const SHARED_TEST_LOG_DOMAIN: number = 0x0000;
const SHARED_TEST_LOG_TAG: string = 'SharedTestPage';

/**
 * 通用交互抽象层测试页。
 * 使用组件化浮层测试遮罩、卡片和关闭交互。
 */
@ComponentV2
export struct SharedInteractionTestPage {
  @Local private app: AppState = useAppState();
  @Local private keyboardOffset: number = 0;
  @Local private undoVisible: boolean = false;
  @Local private progress: number = 0.45;
  @Local private logs: string[] = [];
  private todoRepository: TodoRepository = new TodoRepository();
  @Param actionSheetVisible: boolean = false;
  @Param detailCardVisible: boolean = false;
  @Param actionSheetController: ActionSheetController = new ActionSheetController();
  @Param detailCardController: DetailCardController = new DetailCardController();
  @Event onOpenActionSheet: () => void = () => {};
  @Event onCloseActionSheet: () => void = () => {};
  @Event onOpenDetailCard: () => void = () => {};
  @Event onCloseDetailCard: () => void = () => {};

  private logToConsole(message: string): void {
    hilog.info(SHARED_TEST_LOG_DOMAIN, SHARED_TEST_LOG_TAG, '%{public}s', message);
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
          this.actionSheetController.dismiss();
        });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private buildActionSheet() {
    ActionSheet({
      isVisible: this.actionSheetVisible,
      panelHeight: '60%',
      keyboardOffset: this.keyboardOffset,
      controller: this.actionSheetController,
      onDismiss: () => {
        this.onCloseActionSheet();
      }
    }) {
      this.buildActionSheetContent();
    }
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

  @Builder
  private buildDetailDialog() {
    DetailCard({
      isVisible: this.detailCardVisible,
      controller: this.detailCardController,
      content: this.buildDetailDialogContent,
      onDismiss: () => {
        this.onCloseDetailCard();
        this.logs.push('DetailCard 已关闭');
      }
    });
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

          InteractableCard({
            leftHint: '左滑: 删除',
            rightHint: '右滑: 启动专注',
            enableSwipeLeft: true,
            enableSwipeRight: false,
            onSwipeLeft: () => {
              this.undoVisible = true;
              this.logs.push('InteractableCard 左滑触发');
            },
            onSwipeRight: () => {
              this.logs.push('InteractableCard 右滑触发');
            },
            onCardTap: () => {
              this.onOpenDetailCard();
              this.logs.push('InteractableCard 点击打开详情卡片');
            }
          }) {
            Column({ space: 8 }) {
              Text('交互卡片手势测试')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('左右滑动达到阈值后触发回调。')
                .fontSize(12)
                .fontColor(this.app.theme.palette.textSecondary);
            }
            .alignItems(HorizontalAlign.Start);
          }

          Row({ space: 14 }) {
            Button('+')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.onOpenActionSheet();
                this.logs.push('ActionSheet 打开');
              });

            Button('?')
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

            Button('i')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.onOpenDetailCard();
                this.logs.push('通过 DetailCard 组件打开详情卡片');
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

          Row({ space: 12 }) {
            Text('模拟键盘避让')
              .fontSize(13)
              .fontColor(this.app.theme.palette.textSecondary);

            Slider({ value: this.keyboardOffset, min: 0, max: 220, step: 10 })
              .layoutWeight(1)
              .onChange((value: number) => {
                this.keyboardOffset = value;
              });
          }
          .width('100%');

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

      if (this.undoVisible) {
        UndoNotification({
          message: '已删除一条测试记录',
          actionText: '撤销',
          durationMs: 4000,
          onUndo: () => {
            this.logs.push('UndoNotification 执行撤销');
          },
          onTimeout: () => {
            this.logs.push('UndoNotification 倒计时结束');
          },
          onClose: () => {
            this.undoVisible = false;
          }
        })
          .margin({ left: 16, right: 16, bottom: 16 });
      }

      if (this.actionSheetVisible) {
        this.buildActionSheet();
      }

      if (this.detailCardVisible) {
        this.buildDetailDialog();
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
