import { http } from '@kit.NetworkKit';
import { AppState, useAppState } from '../../app/AppStates';
import { Idea } from '../../core/models/Idea';
import { AIInsight } from '../../core/models/AIInsight';
import { AIService, useAIService } from '../../core/services/AIService';
import { AIInsightRepository } from '../../core/repositories/AIInsightRepository';
import { IdeaPageState, useIdeaPageState } from '../idea/IdeaPageState';
import { UndoStackItem } from '../../components/feedback/UndoNotificationStack';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';

class AIInsightUndoTask {
  taskId: string;
  record: InsightRecord;
  originalIndex: number;
  deadlineMs: number;

  constructor(taskId: string, record: InsightRecord, originalIndex: number, deadlineMs: number) {
    this.taskId = taskId;
    this.record = record;
    this.originalIndex = originalIndex;
    this.deadlineMs = deadlineMs;
  }
}

/**
 * 洞察记录。
 */
export class InsightRecord {
  id: number;
  mode: string; // 'global' | 'selected'
  createdAt: number;
  keywords: string[];
  summary: string;
  fullContent: string;
  noteCount: number;
  totalLength: number;
  pending: boolean;

  constructor(
    id: number,
    mode: string,
    createdAt: number,
    keywords: string[],
    summary: string,
    fullContent: string,
    noteCount: number,
    totalLength: number,
    pending: boolean = false,
  ) {
    this.id = id;
    this.mode = mode;
    this.createdAt = createdAt;
    this.keywords = keywords;
    this.summary = summary;
    this.fullContent = fullContent;
    this.noteCount = noteCount;
    this.totalLength = totalLength;
    this.pending = pending;
  }
}

/**
 * AI 洞察中心状态管理。
 * 管理历史记录、当前对话、流式生成、笔记选择等状态。
 */
@ObservedV2
export class AIInsightState {
  private app: AppState = useAppState();
  private aiService: AIService = useAIService();
  private ideaState: IdeaPageState = useIdeaPageState();
  private repository: AIInsightRepository = new AIInsightRepository();

  @Trace public viewMode: string = 'home'; // 'home' | 'conversation'
  @Trace public records: InsightRecord[] = [];
  @Trace public selectedNoteIds: number[] = [];
  @Trace public undoTasks: Array<AIInsightUndoTask> = [];

  private streamRequest: http.HttpRequest | null = null;
  private historyLoadingTask: Promise<void> | null = null;
  private lastRecordId: number = 0;
  private undoTaskSeq: number = 0;

  get isGenerating(): boolean {
    return this.app.aiInsightSession.isGenerating;
  }

  set isGenerating(value: boolean) {
    this.app.aiInsightSession.isGenerating = value;
  }

  get generatingText(): string {
    return this.app.aiInsightSession.generatingText;
  }

  set generatingText(value: string) {
    this.app.aiInsightSession.generatingText = value;
  }

  get errorMessage(): string {
    return this.app.aiInsightSession.errorMessage;
  }

  set errorMessage(value: string) {
    this.app.aiInsightSession.errorMessage = value;
  }

  get activeRecord(): InsightRecord | null {
    const record = this.app.aiInsightSession.activeRecord;
    if (record.id <= 0) {
      return null;
    }
    return new InsightRecord(
      record.id,
      record.mode,
      record.createdAt,
      record.keywords.slice(),
      record.summary,
      record.fullContent,
      record.noteCount,
      record.totalLength,
      record.pending,
    );
  }

  set activeRecord(value: InsightRecord | null) {
    const target = this.app.aiInsightSession.activeRecord;
    if (value === null) {
      target.reset();
      return;
    }
    target.id = value.id;
    target.mode = value.mode;
    target.createdAt = value.createdAt;
    target.keywords = value.keywords.slice();
    target.summary = value.summary;
    target.fullContent = value.fullContent;
    target.noteCount = value.noteCount;
    target.totalLength = value.totalLength;
    target.pending = value.pending;
  }

  get activeNoteCount(): number {
    if (this.activeRecord !== null) {
      return this.activeRecord.noteCount;
    }
    if (this.app.aiInsightSession.isGenerating) {
      return this.app.aiInsightSession.activeRecord.noteCount;
    }
    return 0;
  }

  get activeTotalLength(): number {
    if (this.activeRecord !== null) {
      return this.activeRecord.totalLength;
    }
    if (this.app.aiInsightSession.isGenerating) {
      return this.app.aiInsightSession.activeRecord.totalLength;
    }
    return 0;
  }

  async refreshRecords(): Promise<void> {
    if (this.historyLoadingTask !== null) {
      return this.historyLoadingTask;
    }

    this.historyLoadingTask = (async (): Promise<void> => {
      try {
        const entities: Array<AIInsight> = await this.repository.findLatest();
        const loadedRecords = entities.map((entity: AIInsight) => this.fromEntity(entity));
        this.records = this.resolveVisibleRecords(this.mergeGeneratingRecord(loadedRecords));
        if (this.records.length > 0) {
          this.lastRecordId = this.records[0].id;
        }
      } catch (_error) {
        // keep in-memory records when database load fails
      } finally {
        this.historyLoadingTask = null;
      }
    })();

    return this.historyLoadingTask;
  }

  // ---- 笔记选择 ----

  selectNote(id: number): void {
    if (!this.selectedNoteIds.includes(id)) {
      this.selectedNoteIds = [...this.selectedNoteIds, id];
    }
  }

  deselectNote(id: number): void {
    this.selectedNoteIds = this.selectedNoteIds.filter((nid: number) => nid !== id);
  }

  isNoteSelected(id: number): boolean {
    return this.selectedNoteIds.includes(id);
  }

  toggleNoteSelection(id: number): void {
    if (this.isNoteSelected(id)) {
      this.deselectNote(id);
    } else {
      this.selectNote(id);
    }
  }

  // ---- 洞察操作 ----

  /**
   * 全量思维分析：取所有笔记内容。
   */
  startGlobalInsight(): void {
    if (this.isGenerating) {
      this.notifyGeneratingLocked();
      return;
    }
    const ideas = this.ideaState.ideas;
    if (ideas.length === 0) {
      return;
    }
    const content = this.prepareContent(ideas);
    const totalLength = ideas.reduce((sum: number, idea: Idea) => sum + this.resolveIdeaTextLength(idea), 0);
    this.performGeneration(content, 'global', ideas.length, totalLength);
  }

  /**
   * 精准洞察：只取选中笔记。
   */
  startSelectedInsight(): void {
    if (this.isGenerating) {
      this.notifyGeneratingLocked();
      return;
    }
    const allIdeas = this.ideaState.ideas;
    const selected = allIdeas.filter((idea: Idea) => this.selectedNoteIds.includes(idea.id));
    if (selected.length === 0) {
      return;
    }
    const content = this.prepareContent(selected);
    const totalLength = selected.reduce((sum: number, idea: Idea) => sum + this.resolveIdeaTextLength(idea), 0);
    this.performGeneration(content, 'selected', selected.length, totalLength);
  }

  /**
   * 停止流式生成，不将未完成内容写入历史。
   */
  stopGeneration(): void {
    this.cancelStream();
    this.isGenerating = false;
    if (this.activeRecord !== null) {
      const activeId = this.activeRecord.id;
      this.records = this.records.filter((item: InsightRecord) => item.id !== activeId);
    }
    this.generatingText = '';
    this.errorMessage = '';
    this.activeRecord = null;
    this.app.aiInsightSession.reset();
    this.viewMode = 'home';
  }

  /**
   * 查看历史记录（直接显示完整 Markdown）。
   */
  openRecord(record: InsightRecord): void {
    if (record.pending) {
      const generatingRecord = this.resolveGeneratingRecord();
      if (generatingRecord !== null && generatingRecord.id === record.id) {
        this.activeRecord = generatingRecord;
        this.errorMessage = '';
        this.viewMode = 'conversation';
        return;
      }
    }
    this.activeRecord = record;
    this.generatingText = record.fullContent;
    this.isGenerating = false;
    this.errorMessage = '';
    this.viewMode = 'conversation';
  }

  /**
   * 从对话流返回首页。
   */
  backToHome(): void {
    this.errorMessage = '';
    this.viewMode = 'home';
  }

  /**
   * 重置笔记选择状态。
   */
  resetSelection(): void {
    this.selectedNoteIds = [];
  }

  /**
   * 复制报告内容到剪贴板。
   */
  copyReport(content: string): void {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
      const systemBoard = pasteboard.getSystemPasteboard();
      systemBoard.setData(pasteData);
      this.safeToast('已复制到剪贴板');
    } catch (_error) {
      this.safeToast('复制失败');
    }
  }

  notifyGeneratingLocked(): void {
    this.safeToast('当前已有洞察正在生成，请稍候');
  }

  requestDeleteRecord(recordId: number): void {
    const normalizedId = recordId > 0 ? recordId : 0;
    if (normalizedId <= 0) {
      return;
    }
    const index = this.records.findIndex((item: InsightRecord) => item.id === normalizedId);
    if (index < 0 || this.hasUndoTaskForRecord(normalizedId)) {
      return;
    }

    const snapshot = this.copyRecord(this.records[index]);
    const taskId = `ai_insight_delete_${this.undoTaskSeq}`;
    this.undoTaskSeq += 1;
    const deadlineMs = Date.now() + 5000;
    this.records = this.records.filter((item: InsightRecord) => item.id !== normalizedId);
    this.undoTasks = [...this.undoTasks, new AIInsightUndoTask(taskId, snapshot, index, deadlineMs)];

    if (this.activeRecord !== null && this.activeRecord.id === normalizedId) {
      this.activeRecord = null;
      this.generatingText = '';
      this.viewMode = 'home';
    }
  }

  buildUndoStackItems(): Array<UndoStackItem> {
    const items: Array<UndoStackItem> = [];
    for (let i = 0; i < this.undoTasks.length; i++) {
      const task = this.undoTasks[i];
      const label = task.record.mode === 'global' ? '全局分析' : '精准分析';
      items.push(new UndoStackItem(task.taskId, `${label}记录已删除`, '撤销', 5000, task.deadlineMs));
    }
    return items;
  }

  undoDelete(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.closeUndo(taskId);

    const exists = this.records.some((item: InsightRecord) => item.id === task.record.id);
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.records.length));
      const before = this.records.slice(0, insertIndex);
      const after = this.records.slice(insertIndex);
      this.records = [...before, this.copyRecord(task.record), ...after];
    }
  }

  async commitDeleteRecord(taskId: string): Promise<void> {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.closeUndo(taskId);
    await this.repository.removeById(task.record.id);
  }

  closeUndo(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: AIInsightUndoTask) => task.taskId !== taskId);
  }

  // ---- 私有方法 ----

  private prepareContent(ideas: Idea[]): string {
    const recent = ideas.slice(0, 20);
    const lines: string[] = [];
    recent.forEach((idea: Idea, index: number) => {
      const title = idea.title.length > 0 ? `【${idea.title}】` : '';
      const content = idea.content.length > 200 ? idea.content.substring(0, 200) + '...' : idea.content;
      lines.push(`${index + 1}. ${title}${content}`);
    });
    return lines.join('\n\n');
  }

  private resolveIdeaTextLength(idea: Idea): number {
    const titleLength: number = idea.title.length;
    const contentLength: number = idea.content.length;
    return titleLength + contentLength;
  }

  private performGeneration(content: string, mode: string, noteCount: number, totalLength: number): void {
    this.cancelStream();
    this.viewMode = 'conversation';
    this.isGenerating = true;
    this.generatingText = '';
    this.errorMessage = '';
    this.activeRecord = null;

    const tempRecord = new InsightRecord(
      this.createRecordId(), mode, Date.now(), [], '', '', noteCount, totalLength, true,
    );
    this.activeRecord = tempRecord;
    this.records = this.resolveVisibleRecords([tempRecord, ...this.records.filter((item: InsightRecord) => item.id !== tempRecord.id)]);

    const onChunk = (text: string): void => {
      if (this.isGenerating) {
        this.generatingText += text;
      }
    };

    const onDone = (): void => {
      if (!this.isGenerating) {
        return;
      }
      this.isGenerating = false;
      this.streamRequest = null;
      this.finalizeRecord(
        this.generatingText,
        this.activeRecord?.mode ?? 'global',
        this.activeRecord?.noteCount ?? 0,
        this.activeRecord?.totalLength ?? 0,
      );
    };

    const onError = (error: string): void => {
      this.streamRequest = null;
      this.errorMessage = error;
      this.isGenerating = false;
      if (this.activeRecord !== null) {
        const activeId = this.activeRecord.id;
        this.records = this.records.filter((item: InsightRecord) => item.id !== activeId);
      }
      this.activeRecord = null;
      this.app.aiInsightSession.reset();
    };

    this.streamRequest = this.aiService.generateInsightStream(content, onChunk, onDone, onError);
  }

  /**
   * 取消当前流式请求。
   */
  private cancelStream(): void {
    if (this.streamRequest !== null) {
      this.streamRequest.destroy();
      this.streamRequest = null;
    }
  }

  private finalizeRecord(content: string, mode: string, noteCount: number, totalLength: number): void {
    const normalizedContent = content.trim();
    if (normalizedContent.length === 0) {
      this.activeRecord = null;
      return;
    }
    const keywords = this.extractKeywords(normalizedContent);
    const summary = this.extractSummary(normalizedContent);
    const recordId = this.activeRecord !== null ? this.activeRecord.id : this.createRecordId();
    const createdAt = this.activeRecord !== null ? this.activeRecord.createdAt : Date.now();
    const record = new InsightRecord(
      recordId, mode, createdAt, keywords, summary, normalizedContent, noteCount, totalLength, false,
    );
    this.activeRecord = record;
    this.generatingText = normalizedContent;
    this.errorMessage = '';
    this.records = this.resolveVisibleRecords([record, ...this.records.filter((item: InsightRecord) => item.id !== record.id)]);
    this.persistRecord(record).then(() => {
      this.isGenerating = false;
      this.historyLoadingTask = null;
      this.refreshRecords();
    }).catch(() => {
      // keep optimistic in-memory record when refresh fails
    });
  }

  private copyRecord(source: InsightRecord): InsightRecord {
    return new InsightRecord(
      source.id,
      source.mode,
      source.createdAt,
      source.keywords.slice(),
      source.summary,
      source.fullContent,
      source.noteCount,
      source.totalLength,
      source.pending,
    );
  }

  private createRecordId(): number {
    const now: number = Date.now();
    if (now <= this.lastRecordId) {
      this.lastRecordId += 1;
    } else {
      this.lastRecordId = now;
    }
    return this.lastRecordId;
  }

  private fromEntity(entity: AIInsight): InsightRecord {
    return new InsightRecord(
      entity.id,
      entity.mode,
      entity.createdAt,
      this.decodeKeywords(entity.keywords),
      entity.summary,
      entity.fullContent,
      entity.noteCount,
      entity.totalLength,
      false,
    );
  }

  private toEntity(record: InsightRecord): AIInsight {
    const entity = new AIInsight();
    entity.id = record.id;
    entity.mode = record.mode;
    entity.keywords = this.encodeKeywords(record.keywords);
    entity.summary = record.summary;
    entity.fullContent = record.fullContent;
    entity.noteCount = record.noteCount;
    entity.totalLength = record.totalLength;
    entity.createdAt = record.createdAt;
    entity.updatedAt = Date.now();
    return entity;
  }

  private encodeKeywords(keywords: string[]): string {
    if (keywords.length === 0) {
      return '';
    }
    return keywords.join('\n');
  }

  private decodeKeywords(raw: string): string[] {
    if (raw.trim().length === 0) {
      return [];
    }

    const parts: string[] = raw.split('\n');
    const keywords: string[] = [];
    for (let i = 0; i < parts.length; i++) {
      const keyword = parts[i].trim();
      if (keyword.length > 0) {
        keywords.push(keyword);
      }
      if (keywords.length >= 4) {
        break;
      }
    }
    return keywords;
  }

  private persistRecord(record: InsightRecord): Promise<void> {
    const entity = this.toEntity(record);
    return this.repository.save(entity);
  }

  private findUndoTask(taskId: string): AIInsightUndoTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  private hasUndoTaskForRecord(recordId: number): boolean {
    return this.undoTasks.some((task: AIInsightUndoTask) => task.record.id === recordId);
  }

  private resolveVisibleRecords(records: InsightRecord[]): InsightRecord[] {
    if (this.undoTasks.length === 0) {
      return records;
    }
    return records.filter((record: InsightRecord) => !this.hasUndoTaskForRecord(record.id));
  }

  private mergeGeneratingRecord(records: InsightRecord[]): InsightRecord[] {
    if (!this.isGenerating) {
      return records;
    }
    const sourceRecord = this.resolveGeneratingRecord();
    if (sourceRecord === null) {
      return records;
    }
    const merged = records.filter((record: InsightRecord) => record.id !== sourceRecord.id);
    return [sourceRecord, ...merged];
  }

  private resolveGeneratingRecord(): InsightRecord | null {
    const activeRecord = this.activeRecord;
    if (activeRecord !== null && activeRecord.pending) {
      return this.copyRecord(activeRecord);
    }
    if (!this.app.aiInsightSession.isGenerating) {
      return null;
    }
    return activeRecord;
  }

  private extractKeywords(markdown: string): string[] {
    const lines = markdown.split('\n');
    const keywords: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.startsWith('## ')) {
        keywords.push(line.substring(3).trim());
      } else if (line.startsWith('### ')) {
        keywords.push(line.substring(4).trim());
      }
      if (keywords.length >= 4) {
        break;
      }
    }
    return keywords;
  }

  private extractSummary(markdown: string): string {
    const lines = markdown.split('\n');
    const contentLines: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.length === 0 || line.startsWith('#')) {
        continue;
      }
      contentLines.push(line);
      if (contentLines.length >= 2) {
        break;
      }
    }
    return contentLines.join(' ');
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1200 });
    } catch (_error) {
      // ignore
    }
  }
}

const AI_INSIGHT_STATE: AIInsightState = new AIInsightState();

export function useAIInsightState(): AIInsightState {
  return AI_INSIGHT_STATE;
}
