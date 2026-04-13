import { CategoryFilter } from "./components/CategoryFilter";
import { TodoCard } from "./components/TodoCard";
import { TodoEditorSheet } from "./components/TodoEditorSheet";
import { TodoDetailOverlay } from "./components/TodoDetailOverlay";
import { CategoryEditorOverlay } from "./components/CategoryEditorOverlay";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { UndoNotification } from "../../components/feedback/UndoNotification";
import { AppOverlayRoute } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";
import { TodoPageState, useTodoPageState } from "./TodoPageState";

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
        title: "待办",
        actionIcon: $r("sys.symbol.magnifyingglass"),
        actionText: "搜索",
        onActionTap: () => {
          this.app.nav.pushOverlayByName(
            AppOverlayRoute.SEARCH,
            this.app.nav.createSearchParam("todo", "搜索待办"),
          );
        },
      }) {
        CategoryFilter()
        TodoCard()
      }

      if (!this.state.undoVisible) {
        FloatingActionButton({
          onTap: async () => {
            await this.state.refreshAll();
            this.state.openCreateTodo();
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
              await this.state.commitDeleteTodo();
            },
            onClose: () => {
              this.state.closeUndo();
            },
          })
        }
        .width("100%")
        .padding({ left: 16, right: 16, bottom: 10 });
      }

      if (this.state.isTodoEditorVisible) {
        TodoEditorSheet()
      }
      if (this.state.isTodoDetailVisible) {
        TodoDetailOverlay()
      }
      if (this.state.isCategoryEditorVisible) {
        CategoryEditorOverlay()
      }
    }
    .width("100%")
    .height("100%");
  }
}
