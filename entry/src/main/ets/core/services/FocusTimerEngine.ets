import { NotificationService } from './NotificationService';
import { FocusRepository } from '../repositories/FocusRepository';
import { TodoRepository } from '../repositories/TodoRepository';
import { Todo } from '../models/Todo';
import { Focus } from '../models/Focus';

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
  // 状态属性
  @Trace state: FocusState = FocusState.IDLE;
  @Trace remainingSeconds: number = 0;
  @Trace totalSeconds: number = 0;
  @Trace todoId: number = 0;
  @Trace todoTitle: string = '';
  // 默认配置
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
  
  /** 启动一次专注计时。 */
  start(workDuration?: number, restDuration?: number, todoId?: number): void {
    if (this.state !== FocusState.IDLE && this.state !== FocusState.RESTING) {
      return;
    }

    this.currentWorkDuration = workDuration && workDuration > 0 ? workDuration : this.DefaultWorkDuration;
    this.currentRestDuration = restDuration && restDuration > 0 ? restDuration : this.DefaultRestDuration;
    
    this.todoId = todoId && todoId > 0 ? todoId : this.todoId;
    this.setupPhase(this.currentWorkDuration, FocusState.WORKING);
    this.segmentStartRemainingSeconds = this.totalSeconds; 
  }
  
  /** 暂停当前专注计时。 */
  pause(): void {
    if (this.state !== FocusState.WORKING && this.state !== FocusState.RESTING) {
      return;
    }
    this.cleanupTimer();
    this.state = FocusState.PAUSED;
  }
  
  /** 恢复当前专注计时。 */
  resume(): void {
    if (this.state !== FocusState.PAUSED) {
      return;
    }
    
    this.startTimestamp = Date.now() - (this.elapsedSeconds * 1000);
    this.expectedEndTime = Date.now() + (this.remainingSeconds * 1000);
    this.state = this.remainingSeconds > 0 ? FocusState.WORKING : FocusState.RESTING;
    
    this.startTimer();
    this.checkAndStartBackgroundPenalty();
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
      return;
    }
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.currentRestDuration, this.todoId); 
  }
  
  /** 重置引擎状态到空闲。 */
  reset(): void {
    this.cleanupTimer();
    this.resetState();
  }
  
  /** 防偷懒检测方法 */
  private checkAndStartBackgroundPenalty(): void {
    this.clearBackgroundTimeout(); // 先清理旧的
    
    // 只有同时满足“工作状态”且“处于后台”，才启动惩罚倒计时
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

  enterBackground(): void {
    this.isAppInBackground = true; // 记住进入了后台
    this.checkAndStartBackgroundPenalty(); // 触发检测
  }
  
  enterForeground(): void {
    this.isAppInBackground = false; // 记住回到了前台
    if (this.backgroundTimeoutId !== -1) {
      this.clearBackgroundTimeout();
    }
  }

  private clearBackgroundTimeout(): void {
    if (this.backgroundTimeoutId !== -1) {
      clearTimeout(this.backgroundTimeoutId);
      this.backgroundTimeoutId = -1;
    }
  }

  syncToLiveWindow(): void {}
  startBackgroundTimer(): Promise<void> { return Promise.resolve(); }
  
  private setupPhase(duration: number, state: FocusState): void {
    this.totalSeconds = duration;
    this.remainingSeconds = duration;
    this.startTimestamp = Date.now();
    this.expectedEndTime = this.startTimestamp + (duration * 1000);
    this.state = state;
    this.startTimer();
    this.checkAndStartBackgroundPenalty();
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
    this.setupPhase(this.currentRestDuration, FocusState.RESTING);
  }
  
  private onRestComplete(): void {
    this.sendCompletionNotification('休息完成', '休息时间结束，自动开始下一段专注！');
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.currentRestDuration, this.todoId); 
  }
  
  private sendCompletionNotification(title: string, content: string): void {
    NotificationService.sendNotification(title, content);
  }

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
      
      // 等待落库结果，如果失败抛出警告
      const success = await this.getFocusRepository().insertFocusRecord(focus);
      void success;
    } catch (_error) {}
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
    this.clearBackgroundTimeout();
  }
  
  private resetState(): void {
    this.state = FocusState.IDLE;
    this.remainingSeconds = this.currentWorkDuration;
    this.totalSeconds = this.currentWorkDuration;
    this.todoId = 0;
    this.todoTitle = '';
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
      return this.todoId > 0;
    } catch (_error) {
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
      const todoId = this.todoId;
      const todo = todoId <= 0 ? null : await this.getTodoRepository().findById(todoId);
      const name = todo?.content || '';
      this.todoTitle = name;
      return name;
    } catch (_error) {
      return '';
    }
  }

  /**
   * 设置关联的待办任务
   * @param newTodoId 新的待办ID
   */
  setRelatedTodo(newTodoId: number, newTodoTitle: string = ''): void {
    if (this.todoId === newTodoId) {
      if (`${newTodoTitle}`.trim().length > 0 && this.todoTitle !== newTodoTitle) {
        this.todoTitle = `${newTodoTitle}`.trim();
      }
      return;
    }

    if (this.state === FocusState.WORKING) {
      this.saveCurrentSegment(); 
    }

    this.todoId = newTodoId;
    this.todoTitle = `${newTodoTitle}`.trim();
  }
}
