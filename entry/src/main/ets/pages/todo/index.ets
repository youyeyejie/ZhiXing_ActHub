import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { TodoPageState, useTodoPageState } from './TodoPageState';

/**
 * 待办模块主页骨架。
 * 当前接入搜索、分类管理与详情编辑弹层。
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
            this.state.openCreateTodo();
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
              await this.state.commitDeleteTodo();
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
