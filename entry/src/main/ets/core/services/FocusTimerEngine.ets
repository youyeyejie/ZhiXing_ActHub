import { NotificationService } from './NotificationService';
import { FocusRepository } from '../repositories/FocusRepository';
import { TodoRepository } from '../repositories/TodoRepository';
import { Todo } from '../models/Todo';

/**
 * * 类功能简介：
 * - 专注计时引擎
 * - 状态机IDLE、WORKING、PAUSED、RESTING状态转换，目前休息后自动开始下一次番茄钟，无限制
 * * 主要接口：
 * - `start(duration?, todoId?)`: 启动一次专注，duration自定义时长（秒，默认1500），todoID：关联待办。
 * - `pause()` / `resume()`: 暂停与恢复当前的专注。
 * - `stop(saveRecord?)`: 中断专注，并触发落库逻辑（todo）。
 * - `skipRest()`: 提前结束休息，直接进入下一轮专注。
 * - `getFormattedRemainingTime()`：获取格式化剩余事件MM：SS
 * * 副作用与外部依赖：
 * - 触发状态变更时，会自动驱动所有绑定了 @Trace 属性的 UI 组件刷新
 * * TODO
 * - 阶段完成时调用 `NotificationService` 通知。
 * - 专注结束时调用 `FocusRepository` 进行数据持久化落库
 * - question：按照每个番茄钟记录or还是记录完整的专注时间（开始、结束、总专注时间）？
 */

export enum FocusState {
  IDLE = 'idle',          // 空闲状态
  WORKING = 'working',    // 工作中（专注阶段）
  PAUSED = 'paused',      // 已暂停
  RESTING = 'resting',    // 休息中
}

@ObservedV2
export class FocusTimerEngine {
  // 状态属性
  @Trace state: FocusState = FocusState.IDLE; //当前专注状态
  @Trace remainingSeconds: number = 0; //当前剩余时间
  @Trace totalSeconds: number = 0; //当前总秒数
  @Trace todoId: string = ''; //关联待办ID
  @Trace focusRecordId: string = ''; //专注记录ID
  
  // 默认配置
  DefaultWorkDuration: number = 1500;
  DefaultRestDuration: number = 20; //tmp，测试用
  
  // 当前使用的专注时长缓存
  private currentWorkDuration: number = this.DefaultWorkDuration;
  
  // private
  private timerId: number = -1; //计时器id
  private startTimestamp: number = 0;
  private expectedEndTime: number = 0;
  private segmentStartRemainingSeconds: number = 0; //记录当前专注片段开始时的剩余秒数（用于切割记录）
  private focusRepository: FocusRepository | null = null; // TODO: 初始化实际的FocusRepository实例
  private todoRepository: TodoRepository | null = null; // TodoRepository实例（延迟初始化）
  
  /**
   * 启动一次专注计时。
   * @param duration 可选的自定义专注时间（秒），默认使用DefaultWorkDuration
   * @param todoId 关联的待办ID，可选
   */
  start(duration?: number, todoId?: string): void {
    if (this.state !== FocusState.IDLE && this.state !== FocusState.RESTING) {
      console.warn('无法在非空闲/休息状态下启动专注');
      return;
    }

    this.currentWorkDuration = duration || this.DefaultWorkDuration;
    this.todoId = todoId || this.todoId;
    this.focusRecordId = this.generateRecordId();
    
    // 初始化阶段状态与计时器
    this.setupPhase(this.currentWorkDuration, FocusState.WORKING);
    this.segmentStartRemainingSeconds = this.totalSeconds; 
    
    console.log(`专注启动：${this.currentWorkDuration}秒，关联待办：${this.todoId || '无'}`);
  }
  
  /** 暂停当前专注计时。 */
  pause(): void {
    if (this.state !== FocusState.WORKING && this.state !== FocusState.RESTING) {
      console.warn('只能在工作中或休息时暂停');
      return;
    }
    
    this.cleanupTimer();
    this.state = FocusState.PAUSED;
    console.log('专注已暂停');
  }
  
  /** 恢复当前专注计时。 */
  resume(): void {
    if (this.state !== FocusState.PAUSED) {
      console.warn('只能在暂停状态下恢复');
      return;
    }
    
    this.startTimestamp = Date.now() - (this.elapsedSeconds * 1000);
    this.expectedEndTime = Date.now() + (this.remainingSeconds * 1000);
    this.state = this.remainingSeconds > 0 ? FocusState.WORKING : FocusState.RESTING;
    
    this.startTimer();
    console.log('专注已恢复');
  }
  
  /**
   * 停止当前专注计时并保存记录。
   * @param saveRecord 是否保存专注记录，默认为true
   */
  stop(saveRecord: boolean = true): void {
    this.cleanupTimer();
    
    if (saveRecord && this.state === FocusState.WORKING) {
      this.saveCurrentSegment();
    }
    
    this.resetState();
    console.log('专注已停止' + (saveRecord ? '，记录已保存' : ''));
  }
  
  /** 跳过当前休息阶段，立即开始下一段专注。 */
  skipRest(): void {
    if (this.state !== FocusState.RESTING) {
      console.warn('只能在休息时跳过');
      return;
    }
    
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.todoId); 
    console.log('休息已跳过，开始下一段专注');
  }
  
  /** 重置引擎状态到空闲。 */
  reset(): void {
    this.cleanupTimer();
    this.resetState();
    console.log('引擎已重置');
  }
  
  // ===== 扩展预留接口 =====
  
  syncToLiveWindow(): void {
    console.log('实况窗同步（预留接口）');
  }
  
  startBackgroundTimer(): Promise<void> {
    console.log('后台计时（预留接口）');
    return Promise.resolve();
  }
  
  // ===== 私有方法 =====
  
  /** 统一配置新阶段的计时与状态 */
  private setupPhase(duration: number, state: FocusState): void {
    this.totalSeconds = duration;
    this.remainingSeconds = duration;
    this.startTimestamp = Date.now();
    this.expectedEndTime = this.startTimestamp + (duration * 1000);
    this.state = state;
    this.startTimer();
  }

  /** 保存当前专注片段，并重置游标 */
  private saveCurrentSegment(): void {
    const segmentElapsed = this.segmentStartRemainingSeconds - this.remainingSeconds;
    if (segmentElapsed > 0) {
      this.saveFocusRecord(segmentElapsed);
      this.segmentStartRemainingSeconds = this.remainingSeconds;
    }
  }

  /** 启动计时器 */
  private startTimer(): void {
    this.cleanupTimer(); 
    this.timerId = setInterval(() => this.tick(), 1000);
  }
  
  /** 计时器回调 */
  private tick(): void {
    const now = Date.now();
    let isComplete = false;
    
    if (this.expectedEndTime > 0) {
      const remainingMs = Math.max(0, this.expectedEndTime - now);
      this.remainingSeconds = Math.ceil(remainingMs / 1000);
      isComplete = remainingMs <= 0;
    } else {
      // 回退逻辑（当expectedEndTime未设置时）
      const elapsedSeconds = Math.floor((now - this.startTimestamp) / 1000);
      isComplete = elapsedSeconds >= this.totalSeconds;
      this.remainingSeconds = isComplete ? 0 : this.totalSeconds - elapsedSeconds;
    }

    if (isComplete) {
      console.log(`tick: 阶段完成，state=${this.state}`);
      this.onStageComplete();
    }
  }
  
  /** 当前阶段完成处理 */
  private onStageComplete(): void {
    this.cleanupTimer();
    this.remainingSeconds = 0;
    
    if (this.state === FocusState.WORKING) {
      this.onWorkComplete();
    } else if (this.state === FocusState.RESTING) {
      this.onRestComplete();
    }
  }
  
  /** 工作阶段完成处理 */
  private onWorkComplete(): void {
    console.log(`工作阶段完成，开始休息。预期结束时间${Date.now() + (this.DefaultRestDuration * 1000)}`);
    this.sendCompletionNotification('专注完成', '恭喜完成一段专注时间！开始休息。');
    
    this.saveCurrentSegment(); // 进入休息前保存最后一段记录
    this.setupPhase(this.DefaultRestDuration, FocusState.RESTING);
  }
  
  /** 休息阶段完成处理 */
  private onRestComplete(): void {
    console.log('休息阶段完成');
    this.sendCompletionNotification('休息完成', '休息时间结束，自动开始下一段专注！');
    
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.todoId); // 自动重启
    console.log('自动开始下一段专注');
  }
  
  /** 发送完成通知 */
  private sendCompletionNotification(title: string, content: string): void {
    console.log(`发送通知：${title} - ${content}`);
    // const notificationService = new NotificationService();
    // notificationService.sendFocusCompletionNotification(title, content);
  }
  
  /** 保存专注记录 */
  private saveFocusRecord(duration: number): void {
    console.log(`保存专注记录：${this.focusRecordId}，真实专注时长：${duration}秒`);
  }
  
  /** 生成记录ID */
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
    this.focusRecordId = '';
    this.startTimestamp = 0;
    this.expectedEndTime = 0;
    this.segmentStartRemainingSeconds = 0; 
  }
  
  // ===== 工具方法 =====
  
  /** 获取格式化剩余时间（MM:SS） */
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
      console.error('hasTodo方法执行失败:', error);
      return false;
    }
  }

  /** 获取当前关联待办的TodoRepository实例 */
  private getTodoRepository(): TodoRepository {
    if (!this.todoRepository) {
      this.todoRepository = new TodoRepository();
      console.log('TodoRepository实例已初始化');
    }
    return this.todoRepository;
  }

  /** 获取当前关联待办的名称 */
  async getTodoName(): Promise<string> {
    try {
      if (!this.hasTodo()) return '';
      
      const todoId = String(this.todoId);
      const todo = await this.getTodoRepository().findById(todoId);
      
      return todo?.content || '';
    } catch (error) {
      console.error('getTodoName方法执行失败:', error);
      return '';
    }
  }

  /**
   * 设置关联的待办任务
   * @param newTodoId 新的待办ID
   */
  setRelatedTodo(newTodoId: string): void {
    if (this.todoId === newTodoId) return;

    if (this.state === FocusState.WORKING) {
      console.log('[任务切换] 正在保存旧任务记录...');
      this.saveCurrentSegment(); // 保存当前切割段并刷新游标
      
      this.focusRecordId = this.generateRecordId();
      console.log(`[任务切换] 记录已切割，新记录 ID: ${this.focusRecordId}，UI总时长保持不变`);
    }

    this.todoId = newTodoId;
  }
}