import { Idea } from '../../core/models/Idea';
import { IdeaRepository } from '../../core/repositories/IdeaRepository';
import { IdeaCard } from './components/IdeaCard';
import { IdeaEditorSheet } from './components/IdeaEditorSheet';
import { HitokotoCard } from './components/HitokotoCard';
import { ActivityHeatmap } from './components/ActivityHeatmap';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 闪记模块主页。
 * 支持闪记列表展示、新建、编辑、删除和搜索。
 */
@ComponentV2
export struct IdeaPage {
  @Local private app: AppState = useAppState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  private repository: IdeaRepository = new IdeaRepository();

  @Local private ideas: Idea[] = [];
  @Local private loading: boolean = false;
  @Local private showEditor: boolean = false;
  @Local private editingIdea: Idea | null = null;
  @Local private selectedIdea: Idea | null = null;

  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
    this.loadIdeas();
  }

  /**
   * 加载闪记列表。
   */
  private async loadIdeas(): Promise<void> {
    this.loading = true;
    try {
      this.ideas = await this.repository.findAll();
      // 按时间倒序
      this.ideas.sort((a: Idea, b: Idea) => b.timestamp - a.timestamp);
    } catch (_error) {
      // 忽略错误
    } finally {
      this.loading = false;
    }
  }

  /**
   * 打开新建闪记。
   */
  private openNewEditor(): void {
    this.editingIdea = null;
    this.showEditor = true;
  }

  /**
   * 打开编辑闪记。
   */
  private openEditIdea(idea: Idea): void {
    this.selectedIdea = idea;
    this.editingIdea = idea;
    this.showEditor = true;
  }

  /**
   * 处理闪记保存成功。
   * Idea 实体没有 @ObservedV2，编辑后属性变更不会触发 @Param 刷新，
   * 因此统一重新加载列表保证数据与视图一致。
   */
  private onIdeaSaved(_idea: Idea): void {
    this.loadIdeas();
    this.showEditor = false;
    this.editingIdea = null;
    this.selectedIdea = null;
  }

  /**
   * 处理闪记删除。
   */
  private onIdeaDeleted(idea: Idea): void {
    const index = this.ideas.findIndex((i: Idea) => i.id === idea.id);
    if (index >= 0) {
      this.ideas.splice(index, 1);
    }
    this.selectedIdea = null;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 主页面内容
      MainTabPageLayout({
        title: '闪记',
        actionIcon: $r('sys.media.ohos_ic_public_search_filled'),
        onActionTap: () => {
          this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('idea', '搜索闪记'));
        }
      }) {
        // 一言卡片
        HitokotoCard();

        // 闪记列表
        PageScrollLayout({ space: 12, paddingTop: 12 }) {
          // 列表为空时的占位
          if (!this.loading && this.ideas.length === 0) {
            Column({ space: 12 }) {
              Text('还没有闪记')
                .fontSize(16)
                .fontColor(this.app.theme.palette.textSecondary);
              Text('点击右下角按钮，记录你的灵感')
                .fontSize(14)
                .fontColor(this.app.theme.palette.textTertiary);
            }
            .width('100%')
            .padding({ top: 40, bottom: 40 })
            .alignItems(HorizontalAlign.Center);
          }

          // 闪记列表
          ForEach(this.ideas, (idea: Idea) => {
            IdeaCard({
              idea: idea,
              onDelete: (deleted: Idea) => {
                this.onIdeaDeleted(deleted);
              },
              onTap: (tapped: Idea) => {
                this.openEditIdea(tapped);
              }
            });
          }, (idea: Idea) => idea.id);

          // 热力图
          ActivityHeatmap();

          // 底部留白（给 FAB 留空间）
          Column().height(100);
        }
      }

      // 新建按钮（FAB）
      Button() {
        Image($r('sys.media.ohos_ic_public_add'))
          .width(28)
          .height(28)
          .fillColor('#FFFFFF');
      }
      .type(ButtonType.Circle)
      .width(56)
      .height(56)
      .backgroundColor(this.app.theme.palette.primary)
      .shadow({
        radius: 16,
        color: this.app.theme.palette.primary + '40',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ right: 20, bottom: 100 })
      .onClick(() => {
        this.openNewEditor();
      });

      // 编辑器弹层（全屏遮罩）
      if (this.showEditor) {
        IdeaEditorSheet({
          editIdea: this.editingIdea,
          onSaved: (idea: Idea) => {
            this.onIdeaSaved(idea);
          },
          onDismiss: () => {
            this.showEditor = false;
            this.editingIdea = null;
          }
        });
      }
    }
    .width('100%')
    .height('100%');
  }
}
