import { WeekCalendar } from "./components/WeekCalendar";
import { TimelineView } from "./components/TimelineView";
import { PlanEditorSheet } from "./components/PlanEditorSheet";
import { PlanDetailOverlay } from "./components/PlanDetailOverlay";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { UndoNotification } from "../../components/feedback/UndoNotification";
import { AppOverlayRoute } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";
import { PlanPageState, usePlanPageState } from "./PlanPageState";

/**
 * 日程模块主页。
 * 提供周视图、时间轴列表、右下角新建入口和删除撤销气泡。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();

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
        TimelineView()
      }

      if (!this.state.undoVisible) {
        FloatingActionButton({
          onTap: async () => {
            await this.state.refreshAll();
            this.state.openCreatePlan();
          },
        })
      }

      if (this.state.undoVisible) {
        Column() {
          UndoNotification({
            message: this.state.undoMessage,
            durationMs: 5000,
            onUndo: () => {
              this.state.undoDelete();
            },
            onTimeout: async () => {
              await this.state.commitDeletePlan();
            },
            onClose: () => {
              this.state.closeUndo();
            },
          })
        }
        .width("100%")
        .padding({ left: 16, right: 16, bottom: 10 });
      }

      if (this.state.isEditorVisible) {
        PlanEditorSheet()
      }
      if (this.state.isDetailVisible) {
        PlanDetailOverlay()
      }
    }
    .width("100%")
    .height("100%");
  }
}
