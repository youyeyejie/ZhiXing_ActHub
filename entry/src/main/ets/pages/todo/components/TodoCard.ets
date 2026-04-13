import { AppState, useAppState } from "../../../app/AppStates";
import { InteractableCard } from "../../../components/card/InteractableCard";
import { Todo } from "../../../core/models/Todo";
import { AppRoute } from "../../../app/AppConstants";
import { useTodoPageState, TodoPageState } from "../TodoPageState";

/**
 * 组件功能简介：
 * - 待办列表项组件，封装卡片展示与手势事件透传。
 * - TODO: 尚未接入完成态勾选与专注联动。
 *
 * 可传入项：
 * - @Param title/subtitle: 卡片主副文本。
 * - @Param enableSwipeLeft/enableSwipeRight: 控制左右滑手势开关。
 * - @Event onSwipeLeft/onSwipeRight: 左右滑动作回调。
 * - @Event onCardTap: 点击卡片回调。
 *
 * 返回行为：
 * - 返回一个 `InteractableCard` 包裹的待办内容区。
 *
 * 副作用：
 * - 手势与点击会触发外部事件回调。
 */
@ComponentV2
export struct TodoCard {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Local private suppressDetailOpenUntil: number = 0;

  aboutToAppear(): void {
    // 刷新由 TodoPage 统一触发，避免多子组件重复拉取导致状态被覆盖。
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    return text === "undefined" || text === "null" ? "" : text;
  }

  private resolveTodoTitle(todo: Todo): string {
    const title = this.normalizeText(todo.content);
    return title.length > 0 ? title : "未命名待办";
  }

  private resolveCategoryBorderColor(todo: Todo): string {
    return this.state.resolveCategoryColor(todo.categoryId);
  }

  private resolveCategoryBackgroundColor(todo: Todo): string {
    const color = this.normalizeText(this.resolveCategoryBorderColor(todo));
    if (color.length === 7 && color.charAt(0) === "#") {
      // ArkUI 颜色格式为 #AARRGGBB，这里固定使用浅色透明度。
      return `#1A${color.substring(1)}`;
    }
    if (color.length === 9 && color.charAt(0) === "#") {
      return `#1A${color.substring(3)}`;
    }
    return this.app.theme.palette.surfaceSecondary;
  }

  private markSwipeActionTriggered(): void {
    this.suppressDetailOpenUntil = Date.now() + 280;
  }

  private canOpenDetailNow(): boolean {
    return Date.now() >= this.suppressDetailOpenUntil;
  }

  @Builder
  private buildTodoRow(todo: Todo) {
    InteractableCard({
      leftHint: "删除",
      rightHint: "专注",
      cornerRadius: 14,
      contentPadding: 3,
      outerPaddingVertical: 0,
      shadowRadius: 7,
      shadowOffsetY: 3,
      enableSwipeLeft: true,
      enableSwipeRight: true,
      swipeRightColor: "#3B82F6",
      swipeLeftColor: "#EF4444",
      onSwipeLeft: () => {
        this.markSwipeActionTriggered();
        this.state.requestDeleteTodo(todo.id);
      },
      onSwipeRight: () => {
        this.markSwipeActionTriggered();
        this.app.nav.navigateByName(AppRoute.FOCUS);
      },
    }) {
      Row({ space: 8 }) {
        Toggle({ type: ToggleType.Checkbox, isOn: todo.isDone === 1 })
          .onChange((value: boolean) => {
            this.state.toggleDone(todo.id, value);
          })
        Column({ space: 6 }) {
          Text(this.resolveTodoTitle(todo))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(
              todo.isDone === 1
                ? this.app.theme.palette.textSecondary
                : this.app.theme.palette.textPrimary,
            )
            .decoration({
              type: todo.isDone === 1 ? TextDecorationType.LineThrough : TextDecorationType.None,
            })
            .width("100%")
          Row({ space: 8 }) {
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(this.resolveCategoryBorderColor(todo))
            Text(this.state.resolveCategoryName(todo.categoryId))
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary)
            Blank()

            if (todo.inFocus === 1) {
              Text("专注中").fontSize(12).fontColor(this.app.theme.palette.primary);
            }
          }
          .width("100%")
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .onClick(() => {
          if (!this.canOpenDetailNow()) {
            return;
          }
          this.state.openTodoDetail(todo.id);
        })
      }
      .width("100%")
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Center)
      .border({ width: 1, color: this.resolveCategoryBorderColor(todo) })
      .borderRadius(14)
      .backgroundColor(this.resolveCategoryBackgroundColor(todo))
    };
  }

  /**
   * 渲染待办卡片，并把手势事件透传给页面层。
   */
  build() {
    Column({ space: 4 }) {
      if (this.state.visibleTodos.length === 0) {
        Button() {
          Column({ space: 6 }) {
            Text("暂无待办")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.app.theme.palette.textPrimary)
            Text("点击新增该分类待办")
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary)
          }
          .width("100%")
          .alignItems(HorizontalAlign.Start)
        }
        .type(ButtonType.Normal)
        .stateEffect(true)
        .width("100%")
        .padding(16)
        .borderRadius(20)
        .backgroundColor(this.app.theme.palette.surface)
        .shadow({ radius: 5, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 2 })
        .onClick(async () => {
          await this.state.refreshAll();
          this.state.openCreateTodo();
        });
      } else {
        ForEach(
          this.state.visibleTodos,
          (item: Todo) => {
            this.buildTodoRow(item);
          },
          (item: Todo) => `${item.id}_${item.updatedAt}`,
        );
      }
    }.width("100%");
  }
}
