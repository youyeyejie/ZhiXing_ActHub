import { AppState, useAppState } from '../../../app/AppStates';
import { InteractableCard } from '../../../components/card/InteractableCard';
import { DetailCard, DetailCardController } from '../../../components/card/DetailCard';
import { UndoNotification } from '../../../components/feedback/UndoNotification';
import { AutoSaveText } from '../../../components/form/AutoSaveText';
import { Todo } from '../../../core/models/Todo';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { AppRoute } from '../../../app/AppConstants';
import { useTodoPageState, TodoPageState } from '../TodoPageState';

/**
 * 待办卡片骨架。
 * TODO: 后续补充勾选、右滑开启专注、左滑删除等交互。
 */
@ComponentV2
export struct TodoCard {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  private detailController: DetailCardController = new DetailCardController();

  aboutToAppear(): void {
    // 刷新由 TodoPage 统一触发，避免多子组件重复拉取导致状态被覆盖。
  }

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  private resolveTodoById(todoId: string): Todo | null {
    const found = this.state.todos.find((item: Todo) => item.id === todoId);
    return found ? found : null;
  }

  private resolveEditingTodoCategoryId(): string {
    const todo = this.resolveTodoById(this.state.editingTodoId);
    if (todo === null) {
      return '';
    }
    return this.normalizeId(todo.categoryId);
  }

  @Builder
  private buildTodoRow(todo: Todo) {
    InteractableCard({
      leftHint: '删除',
      rightHint: '专注',
      cornerRadius: 14,
      contentPadding: 3,
      outerPaddingVertical: 0,
      shadowRadius: 7,
      shadowOffsetY: 2,
      enableSwipeLeft: true,
      enableSwipeRight: true,
      swipeRightColor: '#3B82F6',
      swipeLeftColor: '#EF4444',
      onSwipeLeft: () => {
        this.state.requestDeleteTodo(todo.id);
      },
      onSwipeRight: () => {
        this.app.nav.navigateByName(AppRoute.FOCUS);
      }
    }) {
      Row({ space: 8 }) {
        Toggle({ type: ToggleType.Checkbox, isOn: todo.isDone === 1 })
          .onChange((value: boolean) => {
            this.state.toggleDone(todo.id, value);
          });

        Column({ space: 6 }) {
          Text(todo.content)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(todo.isDone === 1 ? this.app.theme.palette.textSecondary : this.app.theme.palette.textPrimary)
            .decoration({ type: todo.isDone === 1 ? TextDecorationType.LineThrough : TextDecorationType.None })
            .width('100%');

          Row({ space: 8 }) {
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(this.state.resolveCategoryColor(todo.categoryId));

            Text(this.state.resolveCategoryName(todo.categoryId))
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);

            Blank();

            if (todo.inFocus === 1) {
              Text('专注中')
                .fontSize(12)
                .fontColor(this.app.theme.palette.primary);
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);
        }
        .layoutWeight(1)
        .onClick(() => {
          this.state.openTodoDetail(todo.id);
        });
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Center)
      .border({ width: 1, color: this.state.resolveCategoryColor(todo.categoryId) })
      .borderRadius(14);
    };
  }

  @Builder
  private buildDetailContent() {
    Column({ space: 12 }) {
      Text('待办详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      // 条件渲染：不存在待办 vs 存在待办
      if (this.resolveTodoById(this.state.editingTodoId) === null) {
        Column({ space: 8 }) {
          Text('未找到待办')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary);
          Text('该待办可能已被删除。')
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary);
        }
        .width('100%');
      } else {
        // 注意：此处不能声明变量，所有对 todo 的访问都直接调用 resolveTodoById!
        AutoSaveText({
          label: '内容',
          placeholder: '请输入待办内容',
          initialValue: this.resolveTodoById(this.state.editingTodoId)!.content,
          debounceMs: 500,
          saveOnBlur: true,
          onAutoSave: (value: string) => {
            this.state.updateTodoContent(this.resolveTodoById(this.state.editingTodoId)!.id, value);
          }
        });

        Text('分类')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary);

        Scroll() {
          Row({ space: 10 }) {
            if (this.state.categories.length === 0) {
              Text('暂无分类')
                .fontSize(12)
                .fontColor(this.app.theme.palette.textSecondary);
            }

            ForEach(this.state.categories, (cat: TodoCategory) => {
              Button(cat.category)
                .type(ButtonType.Capsule)
                .fontSize(12)
                .fontColor(this.resolveEditingTodoCategoryId() === this.normalizeId(cat.id) ?
                  this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
                .backgroundColor(this.resolveEditingTodoCategoryId() === this.normalizeId(cat.id) ?
                  this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
                .borderRadius(999)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .onClick(() => {
                  this.state.updateTodoCategory(this.resolveTodoById(this.state.editingTodoId)!.id, this.normalizeId(cat.id));
                });
            }, (cat: TodoCategory) => `${this.normalizeId(cat.id)}_${this.resolveEditingTodoCategoryId()}`);
          }
          .padding({ top: 2, bottom: 2 });
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');

        Row({ space: 10 }) {
          Button(this.resolveTodoById(this.state.editingTodoId)!.isDone === 1 ? '标为未完成' : '标为已完成')
            .type(ButtonType.Capsule)
            .layoutWeight(1)
            .height(24)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .fontColor(this.app.theme.palette.textPrimary)
            .onClick(() => {
              const todo = this.resolveTodoById(this.state.editingTodoId)!;
              this.state.toggleDone(todo.id, todo.isDone !== 1);
            });

          Button('删除')
            .type(ButtonType.Capsule)
            .layoutWeight(1)
            .height(24)
            .backgroundColor('#EF4444')
            .fontColor(this.app.theme.palette.surface)
            .onClick(() => {
              const todo = this.resolveTodoById(this.state.editingTodoId)!;
              this.state.closeTodoDetail();
              this.state.requestDeleteTodo(todo.id);
            });
        }
        .width('100%');
      }
    }
    .width('100%');
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 4 }) {
        if (this.state.visibleTodos.length === 0) {
          Column({ space: 6 }) {
            Text('暂无待办')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.app.theme.palette.textPrimary);
            Text('点击右下角 + 新建一条待办。')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }
          .width('100%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor(this.app.theme.palette.surface);
        } else {
          ForEach(this.state.visibleTodos, (item: Todo) => {
            this.buildTodoRow(item);
          }, (item: Todo) => `${item.id}_${item.updatedAt}`);
        }
      }
      .width('100%');

      if (this.state.undoVisible) {
        Column() {
          UndoNotification({
            message: this.state.undoMessage,
            durationMs: 5000,
            onUndo: () => {
              this.state.undoDelete();
            },
            onTimeout: async () => {
              await this.state.commitDeleteTodo();
            },
            onClose: () => {
              this.state.closeUndo();
            }
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 });
      }

      if (this.state.isTodoDetailVisible) {
        DetailCard({
          isVisible: true,
          controller: this.detailController,
          onDismiss: () => {
            this.state.closeTodoDetail();
          }
        }) {
          this.buildDetailContent();
        }
      }
    }
    .width('100%');
  }
}
