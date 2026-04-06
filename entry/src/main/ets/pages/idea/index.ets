import { HitokotoCard } from './components/HitokotoCard';
import { IdeaCard } from './components/IdeaCard';
import { IdeaEditorSheet } from './components/IdeaEditorSheet';
import { ActivityHeatmap } from './components/ActivityHeatmap';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 闪记模块主页骨架。
 * TODO: 后续接入搜索遮罩、单列流式列表和详情卡片。
 */
@ComponentV2
export struct IdeaPage {
  @Local private app: AppState = useAppState();

  build() {
    MainTabPageLayout({
      title: '闪记',
      actionIcon: '?',
      actionText: '搜索',
      actionFillColor: this.app.theme.palette.primary,
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('idea', '搜索闪记'));
      }
    }) {
      HitokotoCard();
      IdeaCard();
      ActivityHeatmap();
      IdeaEditorSheet();
    }
  }
}
