import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口、浮动新建按钮和详情弹层。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();

  build() {
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
      PlanCard();
      PlanEditorSheet();
    }
  }
}
