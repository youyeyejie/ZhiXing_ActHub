import { AppState, useAppState } from "../../../app/AppStates";
import { PlanItem, PlanPageState, usePlanPageState } from "../PlanPageState";
import { PlanCardListItem } from "./PlanCardListItem";

/**
 * 时间轴容器。
 * 左侧纵向时间轴，右侧日程交互卡片列表。
 */
@ComponentV2
export struct TimelineView {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  @Local private restoreMoveScheduledIds: Set<number> = new Set<number>();
  private restoreMoveDispatchTimers: Map<number, number> = new Map<number, number>();

  aboutToDisappear(): void {
    for (const timerId of this.restoreMoveDispatchTimers.values()) {
      clearTimeout(timerId);
    }
    this.restoreMoveDispatchTimers.clear();
  }

  @Monitor("state.visiblePlanCards")
  onVisiblePlanCardsChanged(): void {
    this.reconcileRestoreMoveScheduledIds();
  }

  private resolvePlanId(plan: PlanItem): number {
    return plan.id > 0 ? plan.id : 0;
  }

  private reconcileRestoreMoveScheduledIds(): void {
    const visibleIds: Set<number> = new Set<number>();
    for (let i = 0; i < this.state.visiblePlanCards.length; i++) {
      const id = this.resolvePlanId(this.state.visiblePlanCards[i]);
      if (id > 0) {
        visibleIds.add(id);
      }
    }

    const next = new Set(this.restoreMoveScheduledIds);
    for (const id of next.values()) {
      if (visibleIds.has(id) && this.state.isPlanPendingRestoreMove(id)) {
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

  private scheduleRestoreMove(plan: PlanItem): void {
    const planId = this.resolvePlanId(plan);
    if (planId <= 0) {
      return;
    }
    if (!this.state.isPlanPendingRestoreMove(planId)) {
      return;
    }
    if (this.restoreMoveScheduledIds.has(planId)) {
      return;
    }

    const nextScheduled = new Set(this.restoreMoveScheduledIds);
    nextScheduled.add(planId);
    this.restoreMoveScheduledIds = nextScheduled;

    const timerId = setTimeout(() => {
      this.restoreMoveDispatchTimers.delete(planId);
      this.state.settlePendingRestoreMove(planId);
    }, 16);
    this.restoreMoveDispatchTimers.set(planId, timerId);
  }

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const minute = date.getMinutes();
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  @Builder
  private buildAxis(timeText: string) {
    Column({ space: 4 }) {
      Text(timeText)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textSecondary)
        .textAlign(TextAlign.Center)
        .width("100%")
      Row()
        .width(1)
        .height(50)
        .backgroundColor(this.app.theme.palette.border)
    }
    .width(56)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 3 });
  }

  @Builder
  private buildPlanRow(plan: PlanItem) {
    Row({ space: 10 }) {
      this.buildAxis(this.formatHourMinute(plan.startTime))
      PlanCardListItem({ plan: plan }).layoutWeight(1)
    }
    .width("100%")
    .alignItems(VerticalAlign.Top)
    .onAppear(() => {
      this.scheduleRestoreMove(plan);
    })
    .animation({ duration: 160, curve: Curve.EaseInOut, playMode: PlayMode.Normal });
  }

  private resolvePlanRenderKey(plan: PlanItem): string {
    const normalizedId = this.resolvePlanId(plan);
    if (normalizedId > 0) {
      return `${normalizedId}`;
    }
    return `plan_fallback_${plan.startTime}_${plan.createdAt}`;
  }

  build() {
    Column({ space: 12 }) {
      if (this.state.visiblePlanCards.length === 0) {
        Column({ space: 12 }) {
          Text("还没有日程")
            .fontSize(16)
            .fontColor(this.app.theme.palette.textSecondary)
          Text("点击右下角按钮，创建日程")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width("100%")
        .padding({ top: 40, bottom: 40 })
        .alignItems(HorizontalAlign.Center);
      }

      Column({ space: 10 }) {
        ForEach(
          this.state.visiblePlanCards,
          (item: PlanItem) => {
            this.buildPlanRow(item);
          },
          (item: PlanItem) => this.resolvePlanRenderKey(item),
        )
      }
      .width("100%")
      .padding(16)
      .borderRadius(20)
      .backgroundColor(this.app.theme.palette.surface)
    }.width("100%");
  }
}
