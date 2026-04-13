import { Idea } from '../../core/models/Idea';
import { IdeaRepository } from '../../core/repositories/IdeaRepository';
import { UndoStackItem } from '../../components/feedback/UndoNotificationStack';

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

@ObservedV2
export class IdeaPageState {
  private repository: IdeaRepository = new IdeaRepository();

  @Trace public ideas: Idea[] = [];
  @Trace public loading: boolean = false;
  @Trace public editingIdeaId: string = '';
  @Trace public undoTasks: Array<IdeaUndoTask> = [];
  private undoTaskSeq: number = 0;
  private refreshTask: Promise<void> | null = null;

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  private sortIdeasByTime(list: Array<Idea>): Array<Idea> {
    const sorted = list.slice();
    sorted.sort((a: Idea, b: Idea) => b.timestamp - a.timestamp);
    return sorted;
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
      } catch (_error) {
      } finally {
        this.loading = false;
        this.refreshTask = null;
      }
    })();
    return this.refreshTask;
  }

  openCreateIdea(): void {
    this.editingIdeaId = '';
  }

  openIdeaDetail(ideaId: string): void {
    this.editingIdeaId = this.normalizeId(ideaId);
  }

  closeIdeaDetail(): void {
    this.editingIdeaId = '';
  }

  findIdeaInMemory(ideaId: string): Idea | null {
    const normalizedId = this.normalizeId(ideaId);
    if (normalizedId.length === 0) {
      return null;
    }
    const found = this.ideas.find((item: Idea) => this.normalizeId(item.id) === normalizedId);
    return found ? found : null;
  }

  applySavedIdea(savedIdea: Idea): void {
    const normalizedId = this.normalizeId(savedIdea.id);
    if (normalizedId.length === 0) {
      this.ideas = [savedIdea, ...this.ideas];
      this.ideas = this.sortIdeasByTime(this.ideas);
      this.closeIdeaDetail();
      return;
    }

    const index = this.ideas.findIndex((item: Idea) => this.normalizeId(item.id) === normalizedId);
    if (index >= 0) {
      this.ideas[index] = savedIdea;
      this.ideas = this.ideas.slice();
    } else {
      this.ideas = [savedIdea, ...this.ideas];
    }
    this.ideas = this.sortIdeasByTime(this.ideas);
    this.closeIdeaDetail();
  }

  requestDeleteIdea(idea: Idea): void {
    const targetId = this.normalizeId(idea.id);
    const index = this.ideas.findIndex((item: Idea) => this.normalizeId(item.id) === targetId);
    if (index < 0) {
      return;
    }

    const taskId = `idea_undo_${this.undoTaskSeq}`;
    this.undoTaskSeq += 1;
    const deadlineMs = Date.now() + 5000;
    this.ideas = this.ideas.filter((item: Idea) => this.normalizeId(item.id) !== targetId);
    this.undoTasks = [...this.undoTasks, new IdeaUndoTask(taskId, idea, index, deadlineMs)];
    if (this.editingIdeaId === targetId) {
      this.closeIdeaDetail();
    }
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

  undoDelete(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    const exists = this.ideas.some((item: Idea) => this.normalizeId(item.id) === this.normalizeId(task.idea.id));
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.ideas.length));
      const before = this.ideas.slice(0, insertIndex);
      const after = this.ideas.slice(insertIndex);
      this.ideas = [...before, task.idea, ...after];
      this.ideas = this.sortIdeasByTime(this.ideas);
    }
  }

  async commitDeleteIdea(taskId: string): Promise<void> {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    await this.repository.removeById(task.idea.id);
  }

  closeUndo(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: IdeaUndoTask) => task.taskId !== taskId);
  }
}

const IDEA_PAGE_STATE: IdeaPageState = new IdeaPageState();

export function useIdeaPageState(): IdeaPageState {
  return IDEA_PAGE_STATE;
}
