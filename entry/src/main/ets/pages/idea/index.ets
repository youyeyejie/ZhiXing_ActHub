import { Idea } from "../../core/models/Idea";
import { IdeaCard } from "./components/IdeaCard";
import { IdeaEditorSheet } from "./components/IdeaEditorSheet";
import { HitokotoCard } from "./components/HitokotoCard";
import { ActivityHeatmap } from "./components/ActivityHeatmap";
import { AIInsightPanel } from "./components/AIInsightPanel";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { UndoNotificationStack, UndoStackItem } from "../../components/feedback/UndoNotificationStack";
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
    IdeaEditorSheet({
      hideInnerHeader: false,
    });
  }

  @Builder
  private buildIdeaDetailContent() {
    IdeaEditorSheet({
      hideInnerHeader: true,
    });
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
  private openEditIdea(idea: Idea): void {
    this.state.openIdeaDetail(idea.id);
    this.app.nav.openDetailCard(this.buildIdeaDetailContent, '编辑闪记');
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
          // 列表为空时的占位
          if (!this.state.loading && this.state.ideas.length === 0) {
            Column({ space: 12 }) {
              Text("还没有闪记")
                .fontSize(16)
                .fontColor(this.app.theme.palette.textSecondary)
              Text("点击右下角按钮，记录你的灵感")
                .fontSize(14)
                .fontColor(this.app.theme.palette.textTertiary)
            }
            .width("100%")
            .padding({ top: 40, bottom: 40 })
            .alignItems(HorizontalAlign.Center);
          }

          // 闪记列表
          ForEach(
            this.state.ideas,
            (idea: Idea) => {
              IdeaCard({
                idea: idea,
                refreshVersion: this.state.refreshVersion,
                onDeleteRequest: (deleting: Idea) => {
                  this.state.requestDeleteIdea(deleting);
                },
                onTap: (tapped: Idea) => {
                  this.openEditIdea(tapped);
                },
              });
            },
            (idea: Idea) => idea.id + '_' + this.state.refreshVersion,
          )

          // 热力图与AI洞察
          Row({ space: 12 }) {
            ActivityHeatmap()
              .layoutWeight(1)

            AIInsightPanel()
          }
          .width("100%")
          .alignItems(VerticalAlign.Top)

          // 底部留白（给 FAB 留空间）
          Column().height(100)
        }
      }

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
