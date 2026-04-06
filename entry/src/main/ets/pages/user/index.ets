import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 我的页面骨架。
 * TODO: 后续接入用户信息、主题切换和统计信息汇总。
 */
@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();

  build() {
    MainTabPageLayout({
      title: '我的',
      actionIcon: '!',
      actionText: '测试',
      actionFillColor: this.app.theme.palette.primary,
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SHARED_TEST);
      }
    }) {
      Text('TODO: 用户信息区与主题切换入口。')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary);
      FocusStatsChart();
      ActivityHeatmap();
      SettingsPanel();
    }
  }
}
