import { WeekCalendar } from "./components/WeekCalendar";
import { TimelineView } from "./components/TimelineView";
import { PlanActionSheetContent } from "./components/PlanActionSheetContent";
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

  @Builder
  private buildPlanEditorContent() {
    PlanActionSheetContent();
  }

  private shouldShowReturnTodayButton(): boolean {
    return !this.state.isSelectedDateToday();
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
        WeekCalendar().width("90%")
        PageScrollLayout({ space: 12, paddingTop: 12 }) {
          TimelineView()
        }
      }

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

      FloatingActionButton({
        onTap: async () => {
          await this.state.refreshAll();
          this.state.openCreatePlan();
          this.app.nav.openActionSheet(this.buildPlanEditorContent, 'auto');
        },
      })

      if (this.shouldShowReturnTodayButton()) {
        FloatingActionButton({
          label: "今",
          onTap: () => {
            this.state.requestReturnToTodayAnimated();
          },
        })
          .translate({ x: 0, y: -76 })
          .transition(
            TransitionEffect.OPACITY.combine(
              TransitionEffect.scale({ x: 0.92, y: 0.92 }),
            ).animation({ duration: 320, curve: Curve.EaseInOut }),
          );
      }
    }
    .width("100%")
    .height("100%");
  }
}
