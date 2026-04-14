import { NotificationService } from './NotificationService';
import { FocusRepository } from '../repositories/FocusRepository';
import { TodoRepository } from '../repositories/TodoRepository';
import { Todo } from '../models/Todo';
import { Focus } from '../models/Focus';
export enum FocusState {
  IDLE = 'idle',          // 空闲状态
  WORKING = 'working',    // 工作中（专注阶段）
  PAUSED = 'paused',      // 已暂停
  RESTING = 'resting',    // 休息中
}

@ObservedV2
export class FocusTimerEngine {
  // 状态属性
  @Trace state: FocusState = FocusState.IDLE;
  @Trace remainingSeconds: number = 0;
  @Trace totalSeconds: number = 0;
  @Trace todoId: string = '';
  @Trace todoTitle: string = '';
  @Trace focusRecordId: string = '';
  
  // 默认配置
  DefaultWorkDuration: number = 1500;
  DefaultRestDuration: number = 20; // tmp，测试用
  
  private currentWorkDuration: number = this.DefaultWorkDuration;
  
  // private
  private timerId: number = -1;
  private startTimestamp: number = 0;
  private expectedEndTime: number = 0;
  private segmentStartRemainingSeconds: number = 0;
  private focusRepository: FocusRepository | null = null;
  private todoRepository: TodoRepository | null = null;
  
  /** 启动一次专注计时。 */
  start(duration?: number, todoId?: string): void {
    if (this.state !== FocusState.IDLE && this.state !== FocusState.RESTING) {
      console.warn('[TimerEngine] 警告: 无法在非空闲/休息状态下启动专注');
      return;
    }

    this.currentWorkDuration = duration || this.DefaultWorkDuration;
    this.todoId = todoId || this.todoId;
    this.focusRecordId = this.generateRecordId();
    
    this.setupPhase(this.currentWorkDuration, FocusState.WORKING);
    this.segmentStartRemainingSeconds = this.totalSeconds; 
  }
  
  /** 暂停当前专注计时。 */
  pause(): void {
    if (this.state !== FocusState.WORKING && this.state !== FocusState.RESTING) {
      console.warn('[TimerEngine] 警告: 只能在工作中或休息时暂停');
      return;
    }
    this.cleanupTimer();
    this.state = FocusState.PAUSED;
  }
  
  /** 恢复当前专注计时。 */
  resume(): void {
    if (this.state !== FocusState.PAUSED) {
      console.warn('[TimerEngine] 警告: 只能在暂停状态下恢复');
      return;
    }
    
    this.startTimestamp = Date.now() - (this.elapsedSeconds * 1000);
    this.expectedEndTime = Date.now() + (this.remainingSeconds * 1000);
    this.state = this.remainingSeconds > 0 ? FocusState.WORKING : FocusState.RESTING;
    
    this.startTimer();
  }
  
  /** 停止当前专注计时并保存记录。 */
  stop(saveRecord: boolean = true): void {
    this.cleanupTimer();
    if (saveRecord && this.state === FocusState.WORKING) {
      this.saveCurrentSegment();
    }
    this.resetState();
  }
  
  /** 跳过当前休息阶段，立即开始下一段专注。 */
  skipRest(): void {
    if (this.state !== FocusState.RESTING) {
      console.warn('[TimerEngine] 警告: 只能在休息时跳过');
      return;
    }
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.todoId); 
  }
  
  /** 重置引擎状态到空闲。 */
  reset(): void {
    this.cleanupTimer();
    this.resetState();
  }
  
  // ===== 扩展预留接口 =====
  syncToLiveWindow(): void {}
  
  startBackgroundTimer(): Promise<void> {
    return Promise.resolve();
  }
  
  // ===== 私有方法 =====
  private setupPhase(duration: number, state: FocusState): void {
    this.totalSeconds = duration;
    this.remainingSeconds = duration;
    this.startTimestamp = Date.now();
    this.expectedEndTime = this.startTimestamp + (duration * 1000);
    this.state = state;
    this.startTimer();
  }

  private saveCurrentSegment(): void {
    const segmentElapsed = this.segmentStartRemainingSeconds - this.remainingSeconds;
    if (segmentElapsed > 0) {
      this.saveFocusRecord(segmentElapsed);
      this.segmentStartRemainingSeconds = this.remainingSeconds;
    }
  }

  private startTimer(): void {
    this.cleanupTimer(); 
    this.timerId = setInterval(() => this.tick(), 1000);
  }
  
  private tick(): void {
    const now = Date.now();
    let isComplete = false;
    
    if (this.expectedEndTime > 0) {
      const remainingMs = Math.max(0, this.expectedEndTime - now);
      this.remainingSeconds = Math.ceil(remainingMs / 1000);
      isComplete = remainingMs <= 0;
    } else {
      const elapsedSeconds = Math.floor((now - this.startTimestamp) / 1000);
      isComplete = elapsedSeconds >= this.totalSeconds;
      this.remainingSeconds = isComplete ? 0 : this.totalSeconds - elapsedSeconds;
    }

    if (isComplete) {
      this.onStageComplete();
    }
  }
  
  private onStageComplete(): void {
    this.cleanupTimer();
    this.remainingSeconds = 0;
    
    if (this.state === FocusState.WORKING) {
      this.onWorkComplete();
    } else if (this.state === FocusState.RESTING) {
      this.onRestComplete();
    }
  }
  
  private onWorkComplete(): void {
    this.sendCompletionNotification('专注完成', '恭喜完成一段专注时间！开始休息。');
    this.saveCurrentSegment(); 
    this.setupPhase(this.DefaultRestDuration, FocusState.RESTING);
  }
  
  private onRestComplete(): void {
    this.sendCompletionNotification('休息完成', '休息时间结束，自动开始下一段专注！');
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.todoId); 
  }
  
  private sendCompletionNotification(title: string, content: string): void {
    console.info(`[TimerEngine] 触发系统通知：${title} - ${content}`);
    NotificationService.sendNotification(title, content);
  }
  /** 异步保存专注记录 */
  private async saveFocusRecord(duration: number): Promise<void> {
    if (duration <= 0) return;

    try {
      const recordId = this.focusRecordId || this.generateRecordId();
      const todoId = String(this.todoId || '');
      const now = Date.now();
      
      const focus = new Focus();
      focus.id = recordId;
      focus.todoId = todoId;
      focus.duration = duration;
      focus.startTime = now - (duration * 1000); 
      focus.endTime = now; 
      focus.timestamp = now;
      focus.createdAt = now;
      focus.updatedAt = now;
      
      // 等待落库结果，如果失败抛出警告
      const success = await this.getFocusRepository().insertFocusRecord(focus);
      if (!success) {
        console.warn(`[TimerEngine] 警告: 专注记录落库失败 (ID: ${recordId})`);
      }
    } catch (error) {
      console.error('[TimerEngine] 严重错误: saveFocusRecord 执行异常:', error);
    }
  }
  
  private generateRecordId(): string {
    return `focus_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /** 获取已过去的时间（秒）*/
  get elapsedSeconds(): number {
    return this.totalSeconds - this.remainingSeconds;
  }
  
  /** 检查是否正在计时 */
  get isCounting(): boolean {
    return this.timerId !== -1;
  }
  
  /** 清理计时器 */
  cleanupTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }
  
  /** 重置状态 */
  private resetState(): void {
    this.state = FocusState.IDLE;
    this.remainingSeconds = this.currentWorkDuration;
    this.totalSeconds = this.currentWorkDuration;
    this.todoId = '';
    this.todoTitle = '';
    this.focusRecordId = '';
    this.startTimestamp = 0;
    this.expectedEndTime = 0;
    this.segmentStartRemainingSeconds = 0; 
  }
  
  // ===== 工具方法 =====
  
  getFormattedRemainingTime(): string {
    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }
  
  /** 获取剩余专注的时间（秒） */
  getLeftSeconds(): number {
    return this.totalSeconds - this.elapsedSeconds;
  }
  
  /** 获取当前阶段名称 */
  getCurrentStageName(): string {
    const stageMap: Record<FocusState, string> = {
      [FocusState.WORKING]: '专注中',
      [FocusState.PAUSED]: '已暂停',
      [FocusState.RESTING]: '休息中',
      [FocusState.IDLE]: '空闲'
    };
    return stageMap[this.state];
  }
  
  /** 检查是否关联了待办 */
  hasTodo(): boolean {
    try {
      return this.todoId != null && !/^\s*$/.test(String(this.todoId));
    } catch (error) {
      console.error('[TimerEngine] 错误: hasTodo 方法执行异常:', error);
      return false;
    }
  }

  /** 获取当前关联待办的TodoRepository实例 */
  private getTodoRepository(): TodoRepository {
    if (!this.todoRepository) {
      this.todoRepository = new TodoRepository();
    }
    return this.todoRepository;
  }

  private getFocusRepository(): FocusRepository {
    if (!this.focusRepository) {
      this.focusRepository = new FocusRepository();
    }
    return this.focusRepository;
  }

  async getTodoName(): Promise<string> {
    try {
      if (!this.hasTodo()) return '';
      if (this.todoTitle.trim().length > 0) {
        return this.todoTitle;
      }
      const todoId = String(this.todoId);
      const todo = await this.getTodoRepository().findById(todoId);
      const name = todo?.content || '';
      this.todoTitle = name;
      return name;
    } catch (error) {
      console.error('[TimerEngine] 错误: getTodoName 方法执行异常:', error);
      return '';
    }
  }

  /**
   * 设置关联的待办任务
   * @param newTodoId 新的待办ID
   */
  setRelatedTodo(newTodoId: string, newTodoTitle: string = ''): void {
    if (this.todoId === newTodoId) {
      if (`${newTodoTitle}`.trim().length > 0 && this.todoTitle !== newTodoTitle) {
        this.todoTitle = `${newTodoTitle}`.trim();
      }
      return;
    }

    if (this.state === FocusState.WORKING) {
      // 仅保留切割关键节点日志
      console.info(`[TimerEngine] 任务切换，正在生成新切片...`);
      this.saveCurrentSegment(); 
      this.focusRecordId = this.generateRecordId();
    }

    this.todoId = newTodoId;
    this.todoTitle = `${newTodoTitle}`.trim();
  }
}