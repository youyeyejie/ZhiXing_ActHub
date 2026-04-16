import { AppState, useAppState } from "../../../app/AppStates";
import { InteractableCard } from "../../../components/card/InteractableCard";
import { IdeaItem, IdeaPageState, useIdeaPageState } from "../IdeaPageState";

/**
 * 闪记列表组件。
 * 负责空态提示与列表渲染，把列表职责从页面层抽离。
 */
@ComponentV2
export struct IdeaCardList {
  @Local private app: AppState = useAppState();
  @Local private state: IdeaPageState = useIdeaPageState();
  @Event onOpenIdea: (ideaId: number) => void = (_ideaId: number): void => {};
  @Local private suppressDetailOpenUntil: number = 0;
  @Local private restoreMoveScheduledIds: Set<number> = new Set<number>();
  private restoreMoveDispatchTimers: Map<number, number> = new Map<number, number>();

  aboutToDisappear(): void {
    for (const timerId of this.restoreMoveDispatchTimers.values()) {
      clearTimeout(timerId);
    }
    this.restoreMoveDispatchTimers.clear();
  }

  @Monitor("state.visibleIdeaCards")
  onVisibleIdeaCardsChanged(): void {
    this.reconcileRestoreMoveScheduledIds();
  }

  private resolveIdeaId(idea: IdeaItem): number {
    return idea.id > 0 ? idea.id : 0;
  }

  private resolveIdeaRenderKey(idea: IdeaItem): string {
    const normalizedId = this.resolveIdeaId(idea);
    if (normalizedId > 0) {
      return `${normalizedId}`;
    }
    return `idea_fallback_${idea.timestamp}_${idea.createdAt}`;
  }

  private markSwipeActionTriggered(): void {
    this.suppressDetailOpenUntil = Date.now() + 280;
  }

  private canOpenDetailNow(): boolean {
    return Date.now() >= this.suppressDetailOpenUntil;
  }

  private reconcileRestoreMoveScheduledIds(): void {
    const visibleIds: Set<number> = new Set<number>();
    for (let i = 0; i < this.state.visibleIdeaCards.length; i++) {
      const id = this.resolveIdeaId(this.state.visibleIdeaCards[i]);
      if (id > 0) {
        visibleIds.add(id);
      }
    }

    const next = new Set(this.restoreMoveScheduledIds);
    for (const id of next.values()) {
      if (visibleIds.has(id) && this.state.isIdeaPendingRestoreMove(id)) {
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

  private scheduleRestoreMove(idea: IdeaItem): void {
    const ideaId = this.resolveIdeaId(idea);
    if (ideaId <= 0) {
      return;
    }
    if (!this.state.isIdeaPendingRestoreMove(ideaId)) {
      return;
    }
    if (this.restoreMoveScheduledIds.has(ideaId)) {
      return;
    }

    const nextScheduled = new Set(this.restoreMoveScheduledIds);
    nextScheduled.add(ideaId);
    this.restoreMoveScheduledIds = nextScheduled;

    const timerId = setTimeout(() => {
      this.restoreMoveDispatchTimers.delete(ideaId);
      this.state.settlePendingRestoreMove(ideaId);
    }, 16);
    this.restoreMoveDispatchTimers.set(ideaId, timerId);
  }

  private onDeleteIdea(ideaId: number): void {
    const target = this.state.findIdeaInMemory(ideaId);
    if (target !== null) {
      this.state.requestDeleteIdea(target);
    }
  }

  /**
   * 格式化时间显示。
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const isYesterday = date.toDateString() === yesterday.toDateString();

    const timeStr = `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;

    if (isToday) {
      return `今天 ${timeStr}`;
    }
    if (isYesterday) {
      return `昨天 ${timeStr}`;
    }
    return `${date.getMonth() + 1}/${date.getDate()} ${timeStr}`;
  }

  @Builder
  private buildIdeaRow(idea: IdeaItem) {
    InteractableCard({
      leftHint: "删除",
      enableSwipeLeft: true,
      enableSwipeRight: false,
      cornerRadius: 20,
      contentPadding: 0,
      outerPaddingVertical: 0,
      shadowRadius: 10,
      shadowOffsetY: 3,
      swipeLeftColor: this.app.theme.palette.danger,
      onSwipeLeft: () => {
        this.markSwipeActionTriggered();
        animateTo({ duration: 180, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
          this.onDeleteIdea(this.resolveIdeaId(idea));
        });
      },
      onCardTap: () => {
        if (!this.canOpenDetailNow()) {
          return;
        }
        this.onOpenIdea(this.resolveIdeaId(idea));
      },
    }) {
      Column({ space: 8 }) {
        if (idea.title && idea.title.length > 0) {
          Text(idea.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }

        Text(idea.content)
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
          .maxLines(6)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.formatTime(idea.timestamp))
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
          .margin({ top: 4 })
      }
      .width("100%")
      .onAppear(() => {
        this.scheduleRestoreMove(idea);
      })
      .padding(16)
      .borderRadius(20)
      .backgroundColor(this.app.theme.palette.surface)
      .alignItems(HorizontalAlign.Start)
      .animation({ duration: 160, curve: Curve.EaseInOut, playMode: PlayMode.Normal })
    };
  }

  build() {
    Column({ space: 12 }) {
      if (!this.state.loading && this.state.visibleIdeaCards.length === 0) {
        Column({ space: 12 }) {
          Text("还没有闪记")
            .fontSize(16)
            .fontColor(this.app.theme.palette.textSecondary)
          Text("点击右下角按钮，记录你的灵感")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width("100%")
        .padding({ top: 40, bottom: 40 })
        .alignItems(HorizontalAlign.Center);
      }

      ForEach(
        this.state.visibleIdeaCards,
        (idea: IdeaItem) => {
          this.buildIdeaRow(idea);
        },
        (idea: IdeaItem) => this.resolveIdeaRenderKey(idea),
      )
    }
    .width("100%");
  }
}
