import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { PlanPageState, usePlanPageState } from './PlanPageState';

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

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      MainTabPageLayout({
        title: '日程',
        actionIcon: '?',
        actionText: '搜索',
        actionFillColor: this.app.theme.palette.primary,
        onActionTap: () => {
          this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('plan', '搜索日程'));
        }
      }) {
        WeekCalendar();
        TimelineView();
      }

      if (!this.state.undoVisible) {
        Button('+')
          .type(ButtonType.Circle)
          .width(64)
          .height(64)
          .fontSize(28)
          .fontColor(this.app.theme.palette.surface)
          .backgroundColor(this.app.theme.palette.primary)
          .shadow({ radius: 14, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 6 })
          .onClick(async () => {
            await this.state.refreshAll();
            this.state.openCreatePlan();
          });
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
            }
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 10 });
      }
    }
    .width('100%')
    .height('100%')
    .padding({ right: 18, bottom: 18 });
  }
}
