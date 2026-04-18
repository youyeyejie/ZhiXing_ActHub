import { http } from '@kit.NetworkKit';
import { Idea } from '../../core/models/Idea';
import { AIInsight } from '../../core/models/AIInsight';
import { AIService, useAIService } from '../../core/services/AIService';
import { AIInsightRepository } from '../../core/repositories/AIInsightRepository';
import { IdeaPageState, useIdeaPageState } from '../idea/IdeaPageState';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';

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

  constructor(
    id: number,
    mode: string,
    createdAt: number,
    keywords: string[],
    summary: string,
    fullContent: string,
    noteCount: number,
    totalLength: number,
  ) {
    this.id = id;
    this.mode = mode;
    this.createdAt = createdAt;
    this.keywords = keywords;
    this.summary = summary;
    this.fullContent = fullContent;
    this.noteCount = noteCount;
    this.totalLength = totalLength;
  }
}

/**
 * AI 洞察中心状态管理。
 * 管理历史记录、当前对话、流式生成、笔记选择等状态。
 */
@ObservedV2
export class AIInsightState {
  private aiService: AIService = useAIService();
  private ideaState: IdeaPageState = useIdeaPageState();
  private repository: AIInsightRepository = new AIInsightRepository();

  @Trace public viewMode: string = 'home'; // 'home' | 'conversation'
  @Trace public records: InsightRecord[] = [];
  @Trace public activeRecord: InsightRecord | null = null;
  @Trace public selectedNoteIds: number[] = [];
  @Trace public isGenerating: boolean = false;
  @Trace public generatingText: string = '';
  @Trace public errorMessage: string = '';
  @Trace public activeNoteCount: number = 0;
  @Trace public activeTotalLength: number = 0;

  private streamRequest: http.HttpRequest | null = null;
  private historyLoadingTask: Promise<void> | null = null;
  private lastRecordId: number = 0;

  async refreshRecords(): Promise<void> {
    if (this.historyLoadingTask !== null) {
      return this.historyLoadingTask;
    }

    this.historyLoadingTask = (async (): Promise<void> => {
      try {
        const entities: Array<AIInsight> = await this.repository.findLatest();
        this.records = entities.map((entity: AIInsight) => this.fromEntity(entity));
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
    const ideas = this.ideaState.ideas;
    if (ideas.length === 0) {
      return;
    }
    const content = this.prepareContent(ideas);
    this.activeNoteCount = ideas.length;
    this.activeTotalLength = ideas.reduce((sum: number, idea: Idea) => sum + this.resolveIdeaTextLength(idea), 0);
    this.performGeneration(content, 'global', ideas.length);
  }

  /**
   * 精准洞察：只取选中笔记。
   */
  startSelectedInsight(): void {
    const allIdeas = this.ideaState.ideas;
    const selected = allIdeas.filter((idea: Idea) => this.selectedNoteIds.includes(idea.id));
    if (selected.length === 0) {
      return;
    }
    const content = this.prepareContent(selected);
    this.activeNoteCount = selected.length;
    this.activeTotalLength = selected.reduce((sum: number, idea: Idea) => sum + this.resolveIdeaTextLength(idea), 0);
    this.performGeneration(content, 'selected', selected.length);
  }

  /**
   * 停止流式生成，以当前已显示文本作为最终结果。
   */
  stopGeneration(): void {
    this.cancelStream();
    this.isGenerating = false;
    if (this.generatingText.length > 0) {
      this.finalizeRecord(
        this.generatingText,
        this.activeRecord?.mode ?? 'global',
        this.activeNoteCount,
        this.activeTotalLength,
      );
    }
  }

  /**
   * 查看历史记录（直接显示完整 Markdown）。
   */
  openRecord(record: InsightRecord): void {
    this.activeRecord = record;
    this.generatingText = record.fullContent;
    this.activeNoteCount = record.noteCount;
    this.activeTotalLength = record.totalLength;
    this.isGenerating = false;
    this.errorMessage = '';
    this.viewMode = 'conversation';
  }

  /**
   * 从对话流返回首页。
   */
  backToHome(): void {
    this.cancelStream();
    this.isGenerating = false;
    this.generatingText = '';
    this.errorMessage = '';
    this.activeRecord = null;
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

  private performGeneration(content: string, mode: string, noteCount: number): void {
    this.cancelStream();
    this.viewMode = 'conversation';
    this.isGenerating = true;
    this.generatingText = '';
    this.errorMessage = '';
    this.activeRecord = null;

    const tempRecord = new InsightRecord(
      this.createRecordId(), mode, Date.now(), [], '', '', noteCount, this.activeTotalLength,
    );
    this.activeRecord = tempRecord;

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
        this.activeNoteCount,
        this.activeTotalLength,
      );
    };

    const onError = (error: string): void => {
      this.streamRequest = null;
      this.errorMessage = error;
      this.isGenerating = false;
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
    const keywords = this.extractKeywords(content);
    const summary = this.extractSummary(content);
    const record = new InsightRecord(
      this.createRecordId(), mode, Date.now(), keywords, summary, content, noteCount, totalLength,
    );
    this.activeRecord = record;
    this.records = [record, ...this.records];
    this.persistRecord(record);
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

  private persistRecord(record: InsightRecord): void {
    const entity = this.toEntity(record);
    this.repository.save(entity).catch(() => {
      // ignore persistence errors and keep in-memory record
    });
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
