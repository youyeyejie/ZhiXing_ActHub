import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { TodoEditorSheet } from './components/TodoEditorSheet';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { TodoPageState, useTodoPageState } from './TodoPageState';

/**
 * 待办模块主页骨架。
 * TODO: 后续接入搜索、分类管理和待办详情弹层。
 */
@ComponentV2
export struct TodoPage {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();

  aboutToAppear(): void {
    this.state.refreshAll();
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      MainTabPageLayout({
        title: '待办',
        actionIcon: '?',
        actionText: '搜索',
        actionFillColor: this.app.theme.palette.primary,
        onActionTap: () => {
          this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索待办'));
        }
      }) {
        CategoryFilter();
        TodoCard();
      }

      // 悬浮“新增待办”按钮与半屏表单：固定在页面右下角，不参与滚动。
      TodoEditorSheet();
    }
  }
}
