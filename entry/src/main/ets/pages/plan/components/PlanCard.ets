import { AppState, useAppState } from "../../../app/AppStates";
import { Plan } from "../../../core/models/Plan";
import { InteractableCard } from "../../../components/card/InteractableCard";
import { AppRoute } from "../../../app/AppConstants";
import { PlanPageState, usePlanPageState } from "../PlanPageState";

/**
 * 日程交互卡片。
 * 支持类型配色、详情展开、左滑删除和右滑进入专注。
 */
@ComponentV2
export struct PlanCard {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  @Param plan: Plan = new Plan();
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
    return location.length > 0 ? location : "未填写地点";
  }

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const minute = date.getMinutes();
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  private resolveDurationText(): string {
    return `${this.formatHourMinute(this.plan.startTime)} - ${this.formatHourMinute(this.plan.endTime)}`;
  }

  private resolveTypeColor(): string {
    if (this.plan.isCourse === 1) {
      return "#F59E0B";
    }
    return this.app.theme.palette.primary;
  }

  private resolveCardBackgroundColor(): string {
    if (this.plan.isCourse === 1) {
      return "#FFF8E8";
    }
    return "#EFF6FF";
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

  build() {
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
        this.state.requestDeletePlan(this.plan.id);
      },
      onSwipeRight: () => {
        this.markSwipeActionTriggered();
        this.app.nav.navigateByName(AppRoute.FOCUS);
      },
      onCardTap: () => {
        if (!this.canOpenDetailNow()) {
          return;
        }
        this.state.openPlanDetail(this.plan.id);
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
        .width("100%")
        .alignItems(VerticalAlign.Center)
      }
      .width("100%")
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .borderRadius(14)
      .border({ width: 1, color: this.resolveTypeColor() })
      .backgroundColor(this.resolveCardBackgroundColor())
    };
  }
}
