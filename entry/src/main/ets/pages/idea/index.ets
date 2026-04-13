import { Idea } from "../../core/models/Idea";
import { IdeaRepository } from "../../core/repositories/IdeaRepository";
import { IdeaCard } from "./components/IdeaCard";
import { IdeaEditorSheet } from "./components/IdeaEditorSheet";
import { HitokotoCard } from "./components/HitokotoCard";
import { ActivityHeatmap } from "./components/ActivityHeatmap";
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";
import { FloatingActionButton } from "../../components/buttons/FloatingActionButton";
import { UndoNotificationStack, UndoStackItem } from "../../components/feedback/UndoNotificationStack";
import { AppOverlayRoute } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";

class IdeaUndoTask {
  taskId: string;
  idea: Idea;
  originalIndex: number;
  deadlineMs: number;

  constructor(taskId: string, idea: Idea, originalIndex: number, deadlineMs: number) {
    this.taskId = taskId;
    this.idea = idea;
    this.originalIndex = originalIndex;
    this.deadlineMs = deadlineMs;
  }
}
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
  @Local private undoTasks: Array<IdeaUndoTask> = [];
  private undoTaskSeq: number = 0;

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
  private requestDeleteIdea(idea: Idea): void {
    const index = this.ideas.findIndex((i: Idea) => i.id === idea.id);
    if (index < 0) {
      return;
    }

    const taskId = `idea_undo_${this.undoTaskSeq}`;
    this.undoTaskSeq = this.undoTaskSeq + 1;
    const deadlineMs = Date.now() + 5000;
    this.ideas = this.ideas.filter((item: Idea) => item.id !== idea.id);
    this.undoTasks = [...this.undoTasks, new IdeaUndoTask(taskId, idea, index, deadlineMs)];
    this.selectedIdea = null;
  }

  private buildUndoStackItems(): Array<UndoStackItem> {
    const list: Array<UndoStackItem> = [];
    for (let i = 0; i < this.undoTasks.length; i++) {
      const task = this.undoTasks[i];
      const title = task.idea.title.length > 0 ? task.idea.title : "闪记";
      list.push(new UndoStackItem(task.taskId, `${title} 已删除`, "撤销", 5000, task.deadlineMs));
    }
    return list;
  }

  private findUndoTask(taskId: string): IdeaUndoTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  private restoreIdeaFromTask(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    const exists = this.ideas.some((item: Idea) => item.id === task.idea.id);
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.ideas.length));
      const before = this.ideas.slice(0, insertIndex);
      const after = this.ideas.slice(insertIndex);
      this.ideas = [...before, task.idea, ...after];
    }
  }

  private commitIdeaDelete(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.repository.removeById(task.idea.id);
  }

  private closeUndoTask(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: IdeaUndoTask) => task.taskId !== taskId);
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
        actionIcon: $r("sys.media.ohos_ic_public_search_filled"),
        onActionTap: () => {
          this.app.nav.pushOverlayByName(
            AppOverlayRoute.SEARCH,
            this.app.nav.createSearchParam("idea", "搜索闪记"),
          );
        },
      }) {
        // 一言卡片
        HitokotoCard()

        // 闪记列表
        PageScrollLayout({ space: 12, paddingTop: 12 }) {
          // 列表为空时的占位
          if (!this.loading && this.ideas.length === 0) {
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
            this.ideas,
            (idea: Idea) => {
              IdeaCard({
                idea: idea,
                onDeleteRequest: (deleting: Idea) => {
                  this.requestDeleteIdea(deleting);
                },
                onTap: (tapped: Idea) => {
                  this.openEditIdea(tapped);
                },
              });
            },
            (idea: Idea) => idea.id,
          )

          // 热力图
          ActivityHeatmap()

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
        tasks: this.buildUndoStackItems(),
        onUndo: (taskId: string) => {
          this.restoreIdeaFromTask(taskId);
        },
        onTimeout: (taskId: string) => {
          this.commitIdeaDelete(taskId);
        },
        onClose: (taskId: string) => {
          this.closeUndoTask(taskId);
        },
      })

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
          },
        });
      }
    }
    .width("100%")
    .height("100%");
  }
}
