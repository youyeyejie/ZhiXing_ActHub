import { Idea } from '../../core/models/Idea';
import { IdeaRepository } from '../../core/repositories/IdeaRepository';
import { UndoStackItem } from '../../components/feedback/UndoNotificationStack';

/**
 * 组件功能简介：
 * - 闪记页面撤销任务对象，保存待恢复数据与时限信息。
 *
 * 可传入项：
 * - 构造参数包含任务 ID、闪记快照、原始索引与截止时间。
 *
 * 返回行为：
 * - 创建撤销任务实例供状态层暂存。
 *
 * 副作用：
 * - 无。
 */
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
 * 组件功能简介：
 * - 闪记卡片视图模型，承载列表渲染所需追踪字段。
 *
 * 可传入项：
 * - `applyFrom(idea)` 传入闪记实体。
 *
 * 返回行为：
 * - 同步并暴露用于 UI 的闪记字段。
 *
 * 副作用：
 * - 更新追踪字段后会触发相关 UI 刷新。
 */
@ObservedV2
export class IdeaItem {
  @Trace id: number = 0;
  @Trace title: string = "";
  @Trace content: string = "";
  @Trace timestamp: number = 0;
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;

  applyFrom(idea: Idea): void {
    this.id = idea.id;
    this.title = idea.title;
    this.content = idea.content;
    this.timestamp = idea.timestamp;
    this.createdAt = idea.createdAt;
    this.updatedAt = idea.updatedAt;
  }
}

/**
 * 组件功能简介：
 * - 闪记页面状态容器，管理闪记列表、编辑态与撤销队列。
 *
 * 可传入项：
 * - 通过公开方法接收新增、更新、删除和筛选操作参数。
 *
 * 返回行为：
 * - 输出页面渲染所需的可见列表、卡片模型和交互状态。
 *
 * 副作用：
 * - 会读写闪记仓储并更新本地响应式状态。
 */
@ObservedV2
export class IdeaPageState {
  private repository: IdeaRepository = new IdeaRepository();

  @Trace public ideas: Array<Idea> = [];
  @Trace public visibleIdeas: Array<Idea> = [];
  @Trace public visibleIdeaCards: Array<IdeaItem> = [];
  @Trace public loading: boolean = false;
  @Trace public editingIdeaId: number = 0;
  @Trace public undoTasks: Array<IdeaUndoTask> = [];
  @Trace public pendingRestoreMoveIdeaIds: Array<number> = [];
  @Trace public refreshVersion: number = 0; // 用于通知子组件刷新
  private undoTaskSeq: number = 0;
  private refreshTask: Promise<void> | null = null;
  private ideaItemMap: Map<number, IdeaItem> = new Map<number, IdeaItem>();

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
  }

  private sortIdeasByTime(list: Array<Idea>): Array<Idea> {
    const sorted = list.slice();
    sorted.sort((a: Idea, b: Idea) => b.timestamp - a.timestamp);
    return sorted;
  }

  private copyIdea(source: Idea): Idea {
    const idea = new Idea();
    idea.id = source.id;
    idea.title = source.title;
    idea.content = source.content;
    idea.length = source.length;
    idea.timestamp = source.timestamp;
    idea.createdAt = source.createdAt;
    idea.updatedAt = source.updatedAt;
    return idea;
  }

  private sortVisibleIdeaList(list: Array<Idea>): Array<Idea> {
    const sorted = this.sortIdeasByTime(list);
    if (this.pendingRestoreMoveIdeaIds.length === 0) {
      return sorted;
    }

    const pendingSet: Set<number> = new Set<number>(
      this.pendingRestoreMoveIdeaIds.map((id: number) => this.normalizeId(id)),
    );
    const normal: Array<Idea> = [];
    const pending: Array<Idea> = [];
    for (let i = 0; i < sorted.length; i++) {
      const ideaId = this.normalizeId(sorted[i].id);
      if (ideaId > 0 && pendingSet.has(ideaId)) {
        pending.push(sorted[i]);
      } else {
        normal.push(sorted[i]);
      }
    }
    return [...normal, ...pending];
  }

  private syncVisibleIdeas(): void {
    const filtered = this.ideas.filter((item: Idea) => !this.hasUndoTaskForIdea(item.id));
    this.visibleIdeas = this.sortVisibleIdeaList(filtered);
    this.syncVisibleIdeaCards();
  }

  private syncVisibleIdeaCards(): void {
    const nextItemMap: Map<number, IdeaItem> = new Map<number, IdeaItem>();
    for (let i = 0; i < this.ideas.length; i++) {
      const idea = this.ideas[i];
      const ideaId = this.normalizeId(idea.id);
      if (ideaId <= 0) {
        continue;
      }
      let item = this.ideaItemMap.get(ideaId);
      if (item === undefined) {
        item = new IdeaItem();
      }
      item.applyFrom(idea);
      nextItemMap.set(ideaId, item);
    }
    this.ideaItemMap = nextItemMap;

    const nextVisibleCards: Array<IdeaItem> = [];
    for (let i = 0; i < this.visibleIdeas.length; i++) {
      const ideaId = this.normalizeId(this.visibleIdeas[i].id);
      if (ideaId <= 0) {
        continue;
      }
      const item = this.ideaItemMap.get(ideaId);
      if (item !== undefined) {
        nextVisibleCards.push(item);
      }
    }
    this.visibleIdeaCards = nextVisibleCards;
  }

  async refreshAll(): Promise<void> {
    if (this.refreshTask !== null) {
      return this.refreshTask;
    }
    this.refreshTask = (async (): Promise<void> => {
      this.loading = true;
      try {
        const list = await this.repository.findAll();
        this.ideas = this.sortIdeasByTime(list);
        this.syncVisibleIdeas();
      } catch (_error) {
      } finally {
        this.loading = false;
        this.refreshTask = null;
      }
    })();
    return this.refreshTask;
  }

  openCreateIdea(): void {
    this.editingIdeaId = 0;
  }

  openIdeaDetail(ideaId: number): void {
    this.editingIdeaId = this.normalizeId(ideaId);
  }

  closeIdeaDetail(): void {
    this.editingIdeaId = 0;
  }

  findIdeaInMemory(ideaId: number): Idea | null {
    const normalizedId = this.normalizeId(ideaId);
    if (normalizedId <= 0) {
      return null;
    }
    const found = this.ideas.find((item: Idea) => this.normalizeId(item.id) === normalizedId);
    return found ? found : null;
  }

  async applySavedIdea(savedIdea: Idea): Promise<void> {
    const normalizedId = this.normalizeId(savedIdea.id);

    // 先从数据库重新加载以确保数据最新，并触发UI刷新
    try {
      const freshList = await this.repository.findAll();
      this.ideas = this.sortIdeasByTime(freshList);
      this.syncVisibleIdeas();
    } catch (_error) {
      // 如果加载失败，尝试就地更新
      if (normalizedId <= 0) {
        // 新增：直接插入到列表开头
        this.ideas = [savedIdea, ...this.ideas];
        this.ideas = this.sortIdeasByTime(this.ideas);
        this.syncVisibleIdeas();
      } else {
        const index = this.ideas.findIndex((item: Idea) => this.normalizeId(item.id) === normalizedId);
        if (index >= 0) {
          // 创建新数组以触发响应式更新
          const newIdeas = [...this.ideas];
          newIdeas[index] = savedIdea;
          this.ideas = this.sortIdeasByTime(newIdeas);
          this.syncVisibleIdeas();
        }
      }
    }

    this.closeIdeaDetail();
    this.refreshVersion += 1;
  }

  requestDeleteIdea(idea: Idea): void {
    const targetId = this.normalizeId(idea.id);
    const index = this.ideas.findIndex((item: Idea) => this.normalizeId(item.id) === targetId);
    if (index < 0) {
      return;
    }
    if (this.hasUndoTaskForIdea(targetId)) {
      return;
    }

    this.clearPendingRestoreMove(targetId);
    const snapshot = this.copyIdea(this.ideas[index]);

    const taskId = `idea_undo_${this.undoTaskSeq}`;
    this.undoTaskSeq += 1;
    const deadlineMs = Date.now() + 5000;
    this.ideas = this.ideas.filter((item: Idea) => this.normalizeId(item.id) !== targetId);
    this.undoTasks = [...this.undoTasks, new IdeaUndoTask(taskId, snapshot, index, deadlineMs)];
    if (this.editingIdeaId === targetId) {
      this.closeIdeaDetail();
    }
    this.syncVisibleIdeas();
  }

  buildUndoStackItems(): Array<UndoStackItem> {
    const list: Array<UndoStackItem> = [];
    for (let i = 0; i < this.undoTasks.length; i++) {
      const task = this.undoTasks[i];
      const title = task.idea.title.length > 0 ? task.idea.title : '闪记';
      list.push(new UndoStackItem(task.taskId, `${title} 已删除`, '撤销', 5000, task.deadlineMs));
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

  private hasUndoTaskForIdea(ideaId: number): boolean {
    const normalizedId = this.normalizeId(ideaId);
    return this.undoTasks.some(
      (task: IdeaUndoTask) => this.normalizeId(task.idea.id) === normalizedId,
    );
  }

  undoDelete(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.closeUndo(taskId);

    const exists = this.ideas.some((item: Idea) => this.normalizeId(item.id) === this.normalizeId(task.idea.id));
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.ideas.length));
      const before = this.ideas.slice(0, insertIndex);
      const after = this.ideas.slice(insertIndex);
      this.ideas = [...before, task.idea, ...after];
      this.ideas = this.sortIdeasByTime(this.ideas);
      this.markIdeaPendingRestoreMove(task.idea.id);
      this.refreshVersion += 1;
    }
    this.syncVisibleIdeas();
  }

  async commitDeleteIdea(taskId: string): Promise<void> {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.closeUndo(taskId);
    this.clearPendingRestoreMove(task.idea.id);
    await this.repository.removeById(task.idea.id);
    await this.refreshAll();
    this.refreshVersion += 1;
  }

  closeUndo(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: IdeaUndoTask) => task.taskId !== taskId);
    this.syncVisibleIdeas();
  }

  isIdeaPendingRestoreMove(ideaId: number): boolean {
    const normalizedId = this.normalizeId(ideaId);
    if (normalizedId <= 0) {
      return false;
    }
    return this.pendingRestoreMoveIdeaIds.some((id: number) => this.normalizeId(id) === normalizedId);
  }

  settlePendingRestoreMove(ideaId: number): void {
    const normalizedId = this.normalizeId(ideaId);
    if (normalizedId <= 0) {
      return;
    }
    if (!this.isIdeaPendingRestoreMove(normalizedId)) {
      return;
    }
    animateTo({ duration: 280, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
      this.clearPendingRestoreMove(normalizedId);
      this.syncVisibleIdeas();
    });
  }

  private markIdeaPendingRestoreMove(ideaId: number): void {
    const normalizedId = this.normalizeId(ideaId);
    if (normalizedId <= 0) {
      return;
    }

    const exists = this.pendingRestoreMoveIdeaIds.some(
      (id: number) => this.normalizeId(id) === normalizedId,
    );
    if (!exists) {
      this.pendingRestoreMoveIdeaIds = [...this.pendingRestoreMoveIdeaIds, normalizedId];
    }
  }

  private clearPendingRestoreMove(ideaId: number): void {
    const normalizedId = this.normalizeId(ideaId);
    if (normalizedId <= 0) {
      return;
    }

    const next = this.pendingRestoreMoveIdeaIds.filter(
      (id: number) => this.normalizeId(id) !== normalizedId,
    );
    if (next.length !== this.pendingRestoreMoveIdeaIds.length) {
      this.pendingRestoreMoveIdeaIds = next;
    }
  }

  resetForReload(): void {
    this.ideas = [];
    this.visibleIdeas = [];
    this.visibleIdeaCards = [];
    this.loading = false;
    this.editingIdeaId = 0;
    this.undoTasks = [];
    this.pendingRestoreMoveIdeaIds = [];
    this.refreshVersion += 1;
    this.refreshTask = null;
    this.ideaItemMap = new Map<number, IdeaItem>();
  }

  clearListCache(): void {
    this.ideas = [];
    this.visibleIdeas = [];
    this.visibleIdeaCards = [];
    this.loading = false;
    this.pendingRestoreMoveIdeaIds = [];
    this.refreshVersion += 1;
    this.refreshTask = null;
    this.ideaItemMap = new Map<number, IdeaItem>();
  }
}

const IDEA_PAGE_STATE: IdeaPageState = new IdeaPageState();

export function useIdeaPageState(): IdeaPageState {
  return IDEA_PAGE_STATE;
}
