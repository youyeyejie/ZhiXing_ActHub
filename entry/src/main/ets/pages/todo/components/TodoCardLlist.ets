import { AppState, useAppState } from "../../../app/AppStates";
import { InteractableCard } from "../../../components/card/InteractableCard";
import { AppRoute } from "../../../app/AppConstants";
import { useTodoPageState, TodoCardItem, TodoPageState } from "../TodoPageState";
import { TodoDetailCardContent } from "./TodoDetailCardContent";

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
export struct TodoCardLlist {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Local private suppressDetailOpenUntil: number = 0;
  @Local private doneVisualOverrides: Map<string, number> = new Map<string, number>();
  @Local private restoreMoveScheduledIds: Set<string> = new Set<string>();
  private restoreMoveDispatchTimers: Map<string, number> = new Map<string, number>();

  aboutToAppear(): void {
    // 刷新由 TodoPage 统一触发，避免多子组件重复拉取导致状态被覆盖。
    this.reconcileDoneVisualOverrides();
    this.reconcileRestoreMoveScheduledIds();
  }

  aboutToDisappear(): void {
    for (const timerId of this.restoreMoveDispatchTimers.values()) {
      clearTimeout(timerId);
    }
    this.restoreMoveDispatchTimers.clear();
  }

  @Monitor("state.visibleTodoCards")
  onVisibleTodoCardsChanged(): void {
    this.reconcileDoneVisualOverrides();
    this.reconcileRestoreMoveScheduledIds();
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    return text === "undefined" || text === "null" ? "" : text;
  }

  private resolveTodoId(todo: TodoCardItem): string {
    return this.normalizeText(todo.id);
  }

  private resolveTodoTitle(todo: TodoCardItem): string {
    const title = this.normalizeText(todo.title);
    return title.length > 0 ? title : "未命名待办";
  }

  private resolveCategoryBorderColor(todo: TodoCardItem): string {
    const localColor = this.normalizeText(todo.categoryColor);
    if (localColor.length > 0) {
      return localColor;
    }
    return this.state.resolveCategoryColor(todo.categoryId);
  }

  private resolveCategoryBackgroundColor(todo: TodoCardItem): string {
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

  private resolveDisplayedDone(todo: TodoCardItem): number {
    const todoId = this.resolveTodoId(todo);
    if (todoId.length === 0) {
      return todo.isDone === 1 ? 1 : 0;
    }
    const override = this.doneVisualOverrides.get(todoId);
    if (override === 0 || override === 1) {
      return override;
    }
    return todo.isDone === 1 ? 1 : 0;
  }

  private isDisplayedDone(todo: TodoCardItem): boolean {
    return this.resolveDisplayedDone(todo) === 1;
  }

  private resolveDisplayedCardOpacity(todo: TodoCardItem): number {
    return this.isDisplayedDone(todo) ? 0.62 : 1;
  }

  private resolveDisplayedTitleColor(todo: TodoCardItem): ResourceColor {
    if (this.isDisplayedDone(todo)) {
      return this.app.theme.palette.textSecondary;
    }
    return this.app.theme.palette.textPrimary;
  }

  private updateDoneVisualOverride(todo: TodoCardItem, isDone: boolean): void {
    const todoId = this.resolveTodoId(todo);
    if (todoId.length === 0) {
      return;
    }
    this.doneVisualOverrides.set(todoId, isDone ? 1 : 0);
    this.doneVisualOverrides = new Map(this.doneVisualOverrides);
  }

  private reconcileDoneVisualOverrides(): void {
    const next = new Map(this.doneVisualOverrides);
    for (const entry of next.entries()) {
      const id = entry[0];
      const doneValue = entry[1];
      const todo = this.state.visibleTodoCards.find((item: TodoCardItem) => this.resolveTodoId(item) === id);
      if (!todo) {
        next.delete(id);
        continue;
      }
      const actualDone = todo.isDone === 1 ? 1 : 0;
      if (actualDone === doneValue) {
        next.delete(id);
      }
    }
    this.doneVisualOverrides = next;
  }

  private reconcileRestoreMoveScheduledIds(): void {
    const visibleIds: Set<string> = new Set<string>();
    for (let i = 0; i < this.state.visibleTodoCards.length; i++) {
      const id = this.resolveTodoId(this.state.visibleTodoCards[i]);
      if (id.length > 0) {
        visibleIds.add(id);
      }
    }

    const next = new Set(this.restoreMoveScheduledIds);
    for (const id of next.values()) {
      if (visibleIds.has(id) && this.state.isTodoPendingRestoreMove(id)) {
        continue;
      }
      const timerId = this.restoreMoveDispatchTimers.get(id);
      if (timerId !== undefined) {
        clearTimeout(timerId);
        this.restoreMoveDispatchTimers.delete(id);
      }
      next.delete(id);
    }
    this.restoreMoveScheduledIds = next;
  }

  private scheduleRestoreMove(todo: TodoCardItem): void {
    const todoId = this.resolveTodoId(todo);
    if (todoId.length === 0) {
      return;
    }
    if (!this.state.isTodoPendingRestoreMove(todoId)) {
      return;
    }
    if (this.restoreMoveScheduledIds.has(todoId)) {
      return;
    }

    const nextScheduled = new Set(this.restoreMoveScheduledIds);
    nextScheduled.add(todoId);
    this.restoreMoveScheduledIds = nextScheduled;

    const timerId = setTimeout(() => {
      this.restoreMoveDispatchTimers.delete(todoId);
      this.state.settlePendingRestoreMove(todoId);
    }, 16);
    this.restoreMoveDispatchTimers.set(todoId, timerId);
  }

  private onTodoDoneChanged(todo: TodoCardItem, isDone: boolean): void {
    this.updateDoneVisualOverride(todo, isDone);
    this.state.toggleDone(todo.id, isDone);
  }

  private onTodoDeleted(todo: TodoCardItem): void {
    animateTo({ duration: 180, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
      this.state.requestDeleteTodo(todo.id);
    });
  }

  private resolveTodoRenderKey(todo: TodoCardItem): string {
    const normalizedId = this.resolveTodoId(todo);
    if (normalizedId.length > 0) {
      return normalizedId;
    }
    return `todo_fallback_${todo.createdAt}_${todo.timestamp}`;
  }

  @Builder
  private buildTodoDetailContent() {
    TodoDetailCardContent();
  }

  @Builder
  private buildTodoRow(todo: TodoCardItem) {
    InteractableCard({
      leftHint: "删除",
      rightHint: "专注",
      cornerRadius: 14,
      contentPadding: 0,
      outerPaddingVertical: 0,
      shadowRadius: 7,
      shadowOffsetY: 3,
      enableSwipeLeft: true,
      enableSwipeRight: true,
      swipeRightColor: this.app.theme.palette.info,
      swipeLeftColor: this.app.theme.palette.danger,
      onSwipeLeft: () => {
        this.markSwipeActionTriggered();
        this.onTodoDeleted(todo);
      },
      onSwipeRight: () => {
        this.markSwipeActionTriggered();
        this.app.focusEngine.setRelatedTodo(this.normalizeText(todo.id), this.resolveTodoTitle(todo));
        this.app.nav.navigateByName(AppRoute.FOCUS);
      },
    }) {
      Row({ space: 8 }) {
        Toggle({ type: ToggleType.Checkbox, isOn: this.isDisplayedDone(todo) })
          .onChange((value: boolean) => {
            animateTo({ duration: 180, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
              this.onTodoDoneChanged(todo, value);
            });
          })
        Column({ space: 6 }) {
          Text(this.resolveTodoTitle(todo))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveDisplayedTitleColor(todo))
            .decoration({
              type: this.isDisplayedDone(todo) ? TextDecorationType.LineThrough : TextDecorationType.None,
            })
            .width("100%")
            .animation({ duration: 180, curve: Curve.EaseInOut, playMode: PlayMode.Normal })
          Row({ space: 8 }) {
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(this.resolveCategoryBorderColor(todo))
            Text(this.normalizeText(todo.categoryName).length > 0 ? todo.categoryName : this.state.resolveCategoryName(todo.categoryId))
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
          this.app.nav.openDetailCard(this.buildTodoDetailContent, "40%");
        })
      }
      .width("100%")
      .onAppear(() => {
        this.scheduleRestoreMove(todo);
      })
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Center)
      .border({ width: 1, color: this.resolveCategoryBorderColor(todo) })
      .borderRadius(14)
      .backgroundColor(this.resolveCategoryBackgroundColor(todo))
      .opacity(this.resolveDisplayedCardOpacity(todo))
      .animation({ duration: 160, curve: Curve.EaseInOut, playMode: PlayMode.Normal })
    };
  }

  /**
   * 渲染待办卡片，并把手势事件透传给页面层。
   */
  build() {
    Column({ space: 4 }) {
      if (this.state.visibleTodoCards.length === 0) {
        Column() {
          Text("无任务")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .width("100%")
        .height(260)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        ForEach(
          this.state.visibleTodoCards,
          (item: TodoCardItem) => {
            this.buildTodoRow(item);
          },
          (item: TodoCardItem) => this.resolveTodoRenderKey(item),
        );
      }
    }
    .width("100%")
    .animation({ duration: 160, curve: Curve.EaseInOut, playMode: PlayMode.Normal });
  }
}
