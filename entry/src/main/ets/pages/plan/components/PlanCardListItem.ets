import { AppState, useAppState } from "../../../app/AppStates";
import { InteractableCard } from "../../../components/card/InteractableCard";
import { PlanItem, PlanPageState, usePlanPageState } from "../PlanPageState";
import { PlanDetailCardContent } from "./PlanDetailCardContent";

/**
 * 日程交互卡片。
 * 支持类型配色、详情展开与左滑删除。
 */
@ComponentV2
export struct PlanCardListItem {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  @Param plan: PlanItem = new PlanItem();
  @Local private suppressDetailOpenUntil: number = 0;

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === "undefined" || text === "null") {
      return "";
    }
    return text;
  }

  private resolveTitle(): string {
    const title = this.normalizeText(this.plan.content);
    return title.length > 0 ? title : "未命名日程";
  }

  private resolveLocation(): string {
    const location = this.normalizeText(this.plan.location);
    return location;
  }

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const minute = date.getMinutes();
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  private formatMonthDay(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getMonth() + 1}/${date.getDate()}`;
  }

  private isSameDay(startTime: number, endTime: number): boolean {
    const startDate = new Date(startTime);
    const endDate = new Date(endTime);
    return startDate.getFullYear() === endDate.getFullYear() &&
      startDate.getMonth() === endDate.getMonth() &&
      startDate.getDate() === endDate.getDate();
  }

  private resolveDurationText(): string {
    if (!this.isSameDay(this.plan.startTime, this.plan.endTime)) {
      return `${this.formatMonthDay(this.plan.startTime)} ${this.formatHourMinute(this.plan.startTime)} - ${this.formatMonthDay(this.plan.endTime)} ${this.formatHourMinute(this.plan.endTime)}`;
    }
    return `${this.formatHourMinute(this.plan.startTime)} - ${this.formatHourMinute(this.plan.endTime)}`;
  }

  private resolveTypeColor(): string {
    if (this.plan.isCourse === 1) {
      return this.app.theme.palette.warning;
    }
    return this.app.theme.palette.primary;
  }

  private resolveCardBackgroundColor(): string {
    if (this.plan.isCourse === 1) {
      return this.app.theme.palette.warningSurface;
    }
    return this.app.theme.palette.infoSurface;
  }

  private resolveTypeLabel(): string {
    return this.plan.isCourse === 1 ? "课程" : "日程";
  }

  private markSwipeActionTriggered(): void {
    this.suppressDetailOpenUntil = Date.now() + 280;
  }

  private canOpenDetailNow(): boolean {
    return Date.now() >= this.suppressDetailOpenUntil;
  }

  @Builder
  private buildPlanDetailContent() {
    PlanDetailCardContent();
  }

  build() {
    InteractableCard({
      leftHint: "删除",
      cornerRadius: 14,
      contentPadding: 0,
      outerPaddingVertical: 0,
      shadowRadius: 7,
      shadowOffsetY: 3,
      enableSwipeLeft: true,
      enableSwipeRight: false,
      swipeLeftColor: this.app.theme.palette.danger,
      onSwipeLeft: () => {
        this.markSwipeActionTriggered();
        animateTo({ duration: 180, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
          this.state.requestDeletePlan(this.plan.id);
        });
      },
      onCardTap: () => {
        if (!this.canOpenDetailNow()) {
          return;
        }
        this.state.openPlanDetail(this.plan.id);
        this.app.nav.openDetailCard(this.buildPlanDetailContent, "55%");
      },
    }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text(this.resolveTitle())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.resolveTypeLabel())
            .fontSize(11)
            .fontColor(this.resolveTypeColor())
            .backgroundColor(this.app.theme.palette.surface)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(999)
        }
        .width("100%")
        .alignItems(VerticalAlign.Center)

        Row({ space: 8 }) {
          Text(this.resolveDurationText())
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary)
          if (this.resolveLocation().length > 0) {
            Text("·")
              .fontSize(12)
              .fontColor(this.app.theme.palette.textTertiary)
            Text(this.resolveLocation())
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width("100%")
        .alignItems(VerticalAlign.Center)
      }
      .width("100%")
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .borderRadius(14)
      .border({ width: 1, color: this.resolveTypeColor() })
      .backgroundColor(this.resolveCardBackgroundColor())
      .animation({ duration: 160, curve: Curve.EaseInOut, playMode: PlayMode.Normal })
    };
  }
}
