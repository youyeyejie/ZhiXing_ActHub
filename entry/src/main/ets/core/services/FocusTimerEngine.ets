import { NotificationService } from './NotificationService';
import { FocusRepository } from '../repositories/FocusRepository';
import { TodoRepository } from '../repositories/TodoRepository';
import { Todo } from '../models/Todo';
import { Focus } from '../models/Focus';
import { FocusLiveViewManager } from './FocusLiveViewManager';


/**
 * 组件功能简介：
 * - 专注倒计时核心引擎，负责管理专注/休息状态机、计时器循环、记录切片保存以及系统通知发送。
 *
 * 可传入项：
 * - 无 UI @Param 参数。对外提供各种操作方法（start, pause, resume, stop, skipRest, setRelatedTodo等）供视图层调用。
 *
 * 返回行为：
 * - 通过 @Trace 暴露引擎的实时状态（state, remainingSeconds, totalSeconds, todoId, todoTitle），供订阅了这些状态的 UI 组件响应式刷新。
 *
 * 副作用：
 * - startTimer 时会触发 JavaScript 的 setInterval 维持一个每秒执行的计时轮询。
 * - 专注阶段（WORKING）结束或中途切换绑定待办时，会异步调用 FocusRepository 将专注时长分片存入数据库。
 * - 阶段切换时（WORKING -> RESTING 或 RESTING -> WORKING），会触发 NotificationService.sendNotification 抛出系统通知。
 */


export enum FocusState {
  IDLE = 'idle',          
  WORKING = 'working',    
  PAUSED = 'paused',      
  RESTING = 'resting',    
}

@ObservedV2
export class FocusTimerEngine {
  @Trace state: FocusState = FocusState.IDLE;
  @Trace remainingSeconds: number = 0;
  @Trace totalSeconds: number = 0;
  @Trace todoId: number = 0;
  @Trace todoTitle: string = '';

  DefaultWorkDuration: number = 1500;
  DefaultRestDuration: number = 300;
  
  private currentWorkDuration: number = this.DefaultWorkDuration;
  private currentRestDuration: number = this.DefaultRestDuration; 
  private timerId: number = -1;
  private backgroundTimeoutId: number = -1; 
  private isAppInBackground: boolean = false; 

  private startTimestamp: number = 0;
  private expectedEndTime: number = 0;
  private segmentStartRemainingSeconds: number = 0;
  private focusRepository: FocusRepository | null = null;
  private todoRepository: TodoRepository | null = null;
/** 开始专注 */
  start(workDuration?: number, restDuration?: number, todoId?: number): void {
    if (this.state !== FocusState.IDLE && this.state !== FocusState.RESTING) return;
    this.currentWorkDuration = workDuration && workDuration > 0 ? workDuration : this.DefaultWorkDuration;
    this.currentRestDuration = restDuration && restDuration > 0 ? restDuration : this.DefaultRestDuration;
    this.todoId = todoId && todoId > 0 ? todoId : this.todoId;
    this.setupPhase(this.currentWorkDuration, FocusState.WORKING);
    this.segmentStartRemainingSeconds = this.totalSeconds; 
  }
  
  /** 暂停专注 */
  pause(): void {
    if (this.state !== FocusState.WORKING && this.state !== FocusState.RESTING) return;
    this.cleanupTimer();
    this.state = FocusState.PAUSED;
    this.syncLiveView(); 
  }
  
  /** 恢复专注 */
  resume(): void {
    if (this.state !== FocusState.PAUSED) return;
    this.startTimestamp = Date.now() - (this.elapsedSeconds * 1000);
    this.expectedEndTime = Date.now() + (this.remainingSeconds * 1000);
    this.state = this.remainingSeconds > 0 ? FocusState.WORKING : FocusState.RESTING;
    this.startTimer();
    this.checkAndStartBackgroundPenalty();
    this.syncLiveView(); 
  }
  
  /** 停止当前专注并保存记录 */
  stop(saveRecord: boolean = true): void {
    this.cleanupTimer();
    if (saveRecord && this.state === FocusState.WORKING) {
      this.saveCurrentSegment();
    }
    this.resetState();
  }
  
  /** 跳过休息阶段，直接进入下一轮专注 */
  skipRest(): void {
    if (this.state !== FocusState.RESTING) return;
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.currentRestDuration, this.todoId); 
  }
  
  /** 彻底重置引擎状态 */
  reset(): void {
    this.cleanupTimer();
    this.resetState();
  }
  
  /** 检查并启动防偷懒机制（后台超过1分钟自动暂停） */
  private checkAndStartBackgroundPenalty(): void {
    this.clearBackgroundTimeout(); 
    if (this.state === FocusState.WORKING && this.isAppInBackground) {
      this.sendCompletionNotification('专注进行中', '检测到您离开应用，请于1分钟内返回。')
      this.backgroundTimeoutId = setTimeout(() => {
        if (this.state === FocusState.WORKING) {
          this.pause();
          this.sendCompletionNotification('专注被打断', '检测到离开应用超过1分钟，已自动暂停专注。');
        }
      }, 60 * 1000); 
    }
  }

  /** 应用进入后台时的回调 */
  enterBackground(): void {
    this.isAppInBackground = true; 
    this.checkAndStartBackgroundPenalty(); 
  }
  
  /** 应用返回前台时的回调 */
  enterForeground(): void {
    this.isAppInBackground = false; 
    this.clearBackgroundTimeout();
  }

  /** 清理后台倒计时器 */
  private clearBackgroundTimeout(): void {
    if (this.backgroundTimeoutId !== -1) {
      clearTimeout(this.backgroundTimeoutId);
      this.backgroundTimeoutId = -1;
    }
  }

  syncToLiveWindow(): void {}
  startBackgroundTimer(): Promise<void> { return Promise.resolve(); }
  
  /** 配置并启动一个新的阶段（工作或休息） */
  private setupPhase(duration: number, state: FocusState): void {
    this.totalSeconds = duration;
    this.remainingSeconds = duration;
    this.startTimestamp = Date.now();
    this.expectedEndTime = this.startTimestamp + (duration * 1000);
    this.state = state;
    this.startTimer();
    this.checkAndStartBackgroundPenalty();
    this.syncLiveView(); 
  }

  /** 保存当前已经流逝的专注时间切片 */
  private saveCurrentSegment(): void {
    const segmentElapsed = this.segmentStartRemainingSeconds - this.remainingSeconds;
    if (segmentElapsed > 0) {
      this.saveFocusRecord(segmentElapsed);
      this.segmentStartRemainingSeconds = this.remainingSeconds;
    }
  }

  /** 开启底层循环定时器 */
  private startTimer(): void {
    this.cleanupTimer(); 
    this.timerId = setInterval(() => this.tick(), 1000);
  }
  
  /** 核心计时逻辑（每秒被调用一次） */
  private tick(): void {
    const now = Date.now();
    let isComplete = false;
    
    // 基于时间戳差值计算剩余时间，避免 JS 定时器休眠导致的不准
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
  
  /** 阶段倒计时结束事件 */
  private onStageComplete(): void {
    this.cleanupTimer();
    this.remainingSeconds = 0;
    if (this.state === FocusState.WORKING) {
      this.onWorkComplete();
    } else if (this.state === FocusState.RESTING) {
      this.onRestComplete();
    }
  }
  
  /** 专注完成处理逻辑 */
  private onWorkComplete(): void {
    this.sendCompletionNotification('专注完成', '恭喜完成一段专注时间！开始休息。');
    this.saveCurrentSegment(); 
    this.setupPhase(this.currentRestDuration, FocusState.RESTING);
  }
  
  /** 休息完成处理逻辑 */
  private onRestComplete(): void {
    this.sendCompletionNotification('休息完成', '休息时间结束，自动开始下一段专注！');
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.currentRestDuration, this.todoId); 
  }
  
  /** 发送系统本地通知 */
  private sendCompletionNotification(title: string, content: string): void {
    NotificationService.sendNotification(title, content);
  }

  /** 落库保存专注记录 */
  private async saveFocusRecord(duration: number): Promise<void> {
    if (duration <= 0) return;
    try {
      const todoId = this.todoId;
      const now = Date.now();
      const focus = new Focus();
      focus.todoId = todoId > 0 ? todoId : 0;
      focus.duration = duration;
      focus.startTime = now - (duration * 1000); 
      focus.endTime = now; 
      focus.timestamp = now;
      focus.createdAt = now;
      focus.updatedAt = now;
      const success = await this.getFocusRepository().insertFocusRecord(focus);
      void success;
    } catch (_error) {}
  }
  
  /** 获取当前阶段已经过去的时长（秒） */
  get elapsedSeconds(): number {
    return this.totalSeconds - this.remainingSeconds;
  }
  
  /** 引擎是否正在运行计时中 */
  get isCounting(): boolean {
    return this.timerId !== -1;
  }
  
  /** 清除主计时器及相关后台计时器 */
  cleanupTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.clearBackgroundTimeout();
  }
  
  /** 重置内部状态至默认空闲值 */
  private resetState(): void {
    this.state = FocusState.IDLE;
    this.remainingSeconds = this.currentWorkDuration;
    this.totalSeconds = this.currentWorkDuration;
    this.todoId = 0;
    this.todoTitle = '';
    this.startTimestamp = 0;
    this.expectedEndTime = 0;
    this.segmentStartRemainingSeconds = 0; 
    this.syncLiveView(); 
  }
  
  /** 获取格式化的剩余时间字符串 (例如 "25:00") */
  getFormattedRemainingTime(): string {
    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }
  
  /** 获取本轮专注还剩多少秒（如果是休息阶段则含义不同） */
  getLeftSeconds(): number {
    return this.totalSeconds - this.elapsedSeconds;
  }
  
  /** 获取当前阶段中文名称，供 UI 绑定使用 */
  getCurrentStageName(): string {
    const stageMap: Record<FocusState, string> = {
      [FocusState.WORKING]: '专注中',
      [FocusState.PAUSED]: '已暂停',
      [FocusState.RESTING]: '休息中',
      [FocusState.IDLE]: '空闲'
    };
    return stageMap[this.state];
  }
  
  /** 当前引擎是否已关联待办任务 */
  hasTodo(): boolean {
    try { return this.todoId > 0; } catch (_error) { return false; }
  }

  // === 懒加载获取 Repository ===
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

  /** 实况窗状态同步助手：将当前状态传递给实况窗管理器 */
  private syncLiveView(): void {
    if (this.state === FocusState.IDLE) {
      FocusLiveViewManager.stop();
    } else {
      const isPaused = this.state === FocusState.PAUSED;
      const targetEndTime = isPaused 
        ? Date.now() + (this.remainingSeconds * 1000) 
        : this.expectedEndTime;
      FocusLiveViewManager.syncState(
        this.state, 
        this.remainingSeconds, 
        targetEndTime, 
        this.todoTitle
      );
    }
  }

  /** 获取当前关联任务的名称（优先缓存，无缓存则查库） */
  async getTodoName(): Promise<string> {
    try {
      if (!this.hasTodo()) return '';
      if (this.todoTitle.trim().length > 0) return this.todoTitle;
      const todo = this.todoId <= 0 ? null : await this.getTodoRepository().findById(this.todoId);
      const name = todo?.content || '';
      this.todoTitle = name;
      return name;
    } catch (_error) {
      return '';
    }
  }

  /** 设置/切换关联的待办任务 */
  setRelatedTodo(newTodoId: number, newTodoTitle: string = ''): void {
    if (this.todoId === newTodoId) {
      if (`${newTodoTitle}`.trim().length > 0 && this.todoTitle !== newTodoTitle) {
        this.todoTitle = `${newTodoTitle}`.trim();
        this.syncLiveView();
      }
      return;
    }

    // 如果在专注期间切换任务，先将之前的专注时长切片保存下来
    if (this.state === FocusState.WORKING) {
      this.saveCurrentSegment(); 
    }

    this.todoId = newTodoId;
    this.todoTitle = `${newTodoTitle}`.trim();
    if (this.state !== FocusState.IDLE) {
      this.syncLiveView();
    }
  }
}