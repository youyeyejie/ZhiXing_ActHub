import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { TodoEditorSheet } from './components/TodoEditorSheet';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';

/**
 * 待办模块主页骨架。
 * TODO: 后续接入搜索、分类管理和待办详情弹层。
 */
@ComponentV2
export struct TodoPage {
  @Local private app: AppState = useAppState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
  }

  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  build() {
    MainTabPageLayout({
      title: '待办',
      actionIcon: $r('sys.media.ohos_ic_public_search_filled'),
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索待办'));
      }
    }) {
      CategoryFilter();

      PageScrollLayout() {
        TodoCard();
        TodoEditorSheet();
      }
    }
  }
}
