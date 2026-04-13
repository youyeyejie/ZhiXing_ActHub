import { AppState, useAppState } from "../../../app/AppStates";
import { Plan } from "../../../core/models/Plan";
import { PlanPageState, usePlanPageState } from "../PlanPageState";
import { PlanCard } from "./PlanCard";

/**
 * 时间轴容器。
 * 左侧纵向时间轴，右侧日程交互卡片列表。
 */
@ComponentV2
export struct TimelineView {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const minute = date.getMinutes();
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  private async openCreatePlanForSelectedDay(): Promise<void> {
    await this.state.refreshAll();
    this.state.openCreatePlan();
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
        .height(68)
        .backgroundColor(this.app.theme.palette.border)
    }
    .width(56)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 3 });
  }

  @Builder
  private buildPlanRow(plan: Plan) {
    Row({ space: 10 }) {
      this.buildAxis(this.formatHourMinute(plan.startTime))
      PlanCard({ plan: plan }).layoutWeight(1)
    }
    .width("100%")
    .alignItems(VerticalAlign.Top)
    .padding({ bottom: 2 });
  }

  @Builder
  private buildEmptyPlanModuleButton() {
    Button() {
      Column({ space: 10 }) {
        Text("日程列表")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
        Column({ space: 6 }) {
          Text("点击新建当日日程")
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .width("100%")
        .alignItems(HorizontalAlign.Start)
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
    .onClick(async () => {
      await this.openCreatePlanForSelectedDay();
    });
  }

  build() {
    if (this.state.visiblePlans.length === 0) {
      this.buildEmptyPlanModuleButton();
    } else {
      Column({ space: 10 }) {
        Text("日程列表")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        ForEach(
          this.state.visiblePlans,
          (item: Plan) => {
            this.buildPlanRow(item);
          },
          (item: Plan) => `${item.id}_${item.updatedAt}`,
        )
      }
      .width("100%")
      .padding(16)
      .borderRadius(20)
      .backgroundColor(this.app.theme.palette.surface);
    }
  }
}
