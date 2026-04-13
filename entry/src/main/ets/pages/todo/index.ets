import { CategoryFilter } from "./components/CategoryFilter";
import { TodoCard } from "./components/TodoCard";
import { TodoEditorSheet } from "./components/TodoEditorSheet";
import { CategoryEditorOverlay } from "./components/CategoryEditorOverlay";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { UndoNotificationStack } from "../../components/feedback/UndoNotificationStack";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
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

  @Builder
  private buildTodoEditorContent() {
    TodoEditorSheet();
  }

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
        Column({ space: 12 }) {
          CategoryFilter()
          TodoCard()
        }
        .padding({ left: 20, right: 20 });
      }

      FloatingActionButton({
        onTap: async () => {
          await this.state.refreshAll();
          this.state.openCreateTodo();
          this.app.nav.openActionSheet(this.buildTodoEditorContent);
        },
      })

      UndoNotificationStack({
        tasks: this.state.buildUndoStackItems(),
        onUndo: (taskId: string) => {
          this.state.undoDelete(taskId);
        },
        onTimeout: async (taskId: string) => {
          await this.state.commitDeleteTodo(taskId);
        },
        onClose: (taskId: string) => {
          this.state.closeUndo(taskId);
        },
      })

      if (this.state.isCategoryEditorVisible) {
        CategoryEditorOverlay()
      }
    }
    .width("100%")
    .height("100%");
  }
}
