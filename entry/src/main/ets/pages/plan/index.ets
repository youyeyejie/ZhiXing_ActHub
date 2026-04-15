import { WeekCalendar } from "./components/WeekCalendar";
import { TimelineView } from "./components/TimelineView";
import { PlanEditorSheet } from "./components/PlanEditorSheet";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { UndoNotificationStack } from "../../components/feedback/UndoNotificationStack";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { AppOverlayRoute } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";
import { PlanPageState, usePlanPageState } from "./PlanPageState";
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";

/**
 * 日程模块主页。
 * 提供周视图、时间轴列表、右下角新建入口和删除撤销气泡。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  private readonly floatingButtonSize: number = 56;
  private readonly returnTodayGap: number = 20;

  @Builder
  private buildPlanEditorContent() {
    PlanEditorSheet();
  }

  private shouldShowReturnTodayButton(): boolean {
    return !this.state.isSelectedDateToday();
  }

  @Builder
  private buildReturnTodayButton() {
    Button("今")
      .type(ButtonType.Circle)
      .width(this.floatingButtonSize)
      .height(this.floatingButtonSize)
      .fontSize(20)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.app.theme.palette.surface)
      .backgroundColor(this.app.theme.palette.primary)
      .shadow({
        radius: 16,
        color: this.app.theme.palette.primary + "40",
        offsetX: 0,
        offsetY: 4,
      })
      .margin({ right: 20, bottom: "6%" })
      .translate({ x: 0, y: -(this.floatingButtonSize + this.returnTodayGap) })
      .transition(
        TransitionEffect.OPACITY
          .combine(TransitionEffect.scale({ x: 0.92, y: 0.92 }))
          .animation({ duration: 320, curve: Curve.EaseInOut }),
      )
      .onClick(() => {
        this.state.requestReturnToTodayAnimated();
      });
  }

  aboutToAppear(): void {
    this.state.refreshAll();
  }

  /**
   * 渲染日程主页骨架与测试交互入口。
   */
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      MainTabPageLayout({
        title: "日程",
        actionIcon: $r("sys.symbol.magnifyingglass"),
        onActionTap: () => {
          this.app.nav.pushOverlayByName(
            AppOverlayRoute.SEARCH,
            this.app.nav.createSearchParam("plan", "搜索日程"),
          );
        },
      }) {
        WeekCalendar()
        .width("90%")
        PageScrollLayout({ space: 12, paddingTop: 12 }) {
          TimelineView()
        }
      }

      if (this.shouldShowReturnTodayButton()) {
        this.buildReturnTodayButton();
      }

      FloatingActionButton({
        onTap: async () => {
          await this.state.refreshAll();
          this.state.openCreatePlan();
          this.app.nav.openActionSheet(this.buildPlanEditorContent);
        },
      })

      UndoNotificationStack({
        tasks: this.state.buildUndoStackItems(),
        onUndo: (taskId: string) => {
          this.state.undoDelete(taskId);
        },
        onTimeout: async (taskId: string) => {
          await this.state.commitDeletePlan(taskId);
        },
        onClose: (taskId: string) => {
          this.state.closeUndo(taskId);
        },
      })

    }
    .width("100%")
    .height("100%");
  }
}
