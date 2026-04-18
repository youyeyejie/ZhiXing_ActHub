import { IdeaCardList } from "./components/IdeaCardList";
import { IdeaActionSheetContent } from "./components/IdeaActionSheetContent";
import { IdeaDetailCardContent } from "./components/IdeaDetailCardContent";
import { HitokotoCard } from "./components/HitokotoCard";
import { AIInsightPanel } from "./components/AIInsightPanel";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { UndoNotificationStack } from "../../components/feedback/UndoNotificationStack";
import { AppOverlayRoute } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";
import { IdeaPageState, useIdeaPageState } from "./IdeaPageState";
/**
 * 闪记模块主页。
 * 支持闪记列表展示、新建、编辑、删除和搜索。
 */
@ComponentV2
export struct IdeaPage {
  @Local private app: AppState = useAppState();
  @Local private state: IdeaPageState = useIdeaPageState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  @Builder
  private buildIdeaCreateContent() {
    IdeaActionSheetContent();
  }

  @Builder
  private buildIdeaDetailContent() {
    IdeaDetailCardContent();
  }

  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
    this.state.refreshAll();
  }

  /**
   * 打开新建闪记。
   */
  private openNewEditor(): void {
    this.state.openCreateIdea();
    this.app.nav.openActionSheet(this.buildIdeaCreateContent);
  }

  /**
   * 打开编辑闪记。
   */
  private openEditIdea(ideaId: number): void {
    this.state.openIdeaDetail(ideaId);
    this.app.nav.openDetailCard(this.buildIdeaDetailContent);
  }

  /**
   * 渲染闪记模块测试骨架。
   * TODO: 当前组件多为占位，后续替换为真实数据流和详情交互。
   */
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 主页面内容
      MainTabPageLayout({
        title: "闪记",
        actionIcon: $r("sys.symbol.magnifyingglass"),
        onActionTap: () => {
          this.app.nav.pushOverlayByName(
            AppOverlayRoute.SEARCH,
            this.app.nav.createSearchParam("idea", "搜索闪记"),
          );
        },
      }) {

        // 闪记列表
        PageScrollLayout({ space: 12, paddingTop: 12 }) {
          // 一言卡片
          HitokotoCard()

          IdeaCardList({
            onOpenIdea: (ideaId: number) => {
              this.openEditIdea(ideaId);
            },
          })

          // 底部留白（给 FAB 留空间）
          Column().height(100)
        }
      }

      // 右下角悬浮按钮组：AI 洞察 + 新建
      // AI 洞察按钮（在加号上方 20vp，水平对齐）
      AIInsightPanel()
        .margin({ right: 20, bottom: 96 }) // 76 = FAB高度56 + 间距20

      // 新建按钮（FAB）
      FloatingActionButton({
        onTap: () => {
          this.openNewEditor();
        },
      })

      UndoNotificationStack({
        tasks: this.state.buildUndoStackItems(),
        onUndo: (taskId: string) => {
          this.state.undoDelete(taskId);
        },
        onTimeout: (taskId: string) => {
          this.state.commitDeleteIdea(taskId);
        },
        onClose: (taskId: string) => {
          this.state.closeUndo(taskId);
        },
      })

    }
    .width("100%")
    .height("100%");
  }
}
