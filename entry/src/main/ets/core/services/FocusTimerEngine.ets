import { NotificationService } from './NotificationService';
import { FocusRepository } from '../repositories/FocusRepository';

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
  
  // 当前使用的专注时长缓存（修复自定义时长丢失问题）
  private currentWorkDuration: number = this.DefaultWorkDuration;
  
  // private
  private timerId: number = -1; //计时器id
  private startTimestamp: number = 0;
  private expectedEndTime: number = 0;
  private focusRepository: FocusRepository | null = null; // TODO: 初始化实际的FocusRepository实例
  
  
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
    this.todoId = todoId || '';
    this.totalSeconds = this.currentWorkDuration;
    this.remainingSeconds = this.totalSeconds;
    this.startTimestamp = Date.now();
    this.expectedEndTime = this.startTimestamp + (this.totalSeconds * 1000); // 时间戳校准：记录预期结束时间
    this.state = FocusState.WORKING;
    
    // 创建专注记录
    this.focusRecordId = this.generateRecordId();
    // 启动计时器
    this.startTimer();
    
    console.log(`专注启动：${this.currentWorkDuration}秒，关联待办：${this.todoId || '无'}`);
  }
  
  /**
   * 暂停当前专注计时。
   */
  pause(): void {
    if (this.state !== FocusState.WORKING && this.state !== FocusState.RESTING) {
      console.warn('只能在工作中或休息时暂停');
      return;
    }
    
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    
    this.state = FocusState.PAUSED;
    
    console.log('专注已暂停');
  }
  
  /**
   * 恢复当前专注计时。
   */
  resume(): void {
    if (this.state !== FocusState.PAUSED) {
      console.warn('只能在暂停状态下恢复');
      return;
    }
    
    this.startTimestamp = Date.now() - (this.elapsedSeconds * 1000);
    this.state = this.remainingSeconds > 0 ? FocusState.WORKING : FocusState.RESTING;
    // 修复resume()导致的时间跳跃崩溃：重新推算预期的结束时间
    this.expectedEndTime = Date.now() + (this.remainingSeconds * 1000);
    
    this.startTimer();
    
    console.log('专注已恢复');
  }
  
  /**
   * 停止当前专注计时并保存记录。
   * @param saveRecord 是否保存专注记录，默认为true
   */
  stop(saveRecord: boolean = true): void {
    this.cleanupTimer();
    
    // 保存专注记录（如果专注已完成）
    // 修复"自动循环"导致的专注记录丢失：避免重复保存，只在WORKING状态且专注时长>0时保存
    if (saveRecord && this.state === FocusState.WORKING && this.elapsedSeconds > 0) {
      this.saveFocusRecord();
    }
    
    // 重置状态
    this.resetState();
    
    console.log('专注已停止' + (saveRecord ? '，记录已保存' : ''));
  }
  
  /**
   * 跳过当前休息阶段，立即开始下一段专注。
   */
  skipRest(): void {
    if (this.state !== FocusState.RESTING) {
      console.warn('只能在休息时跳过');
      return;
    }
    
    this.cleanupTimer();
    this.start(this.currentWorkDuration, this.todoId); // 使用当前工作时长（修复自定义时长丢失问题）
    
    console.log('休息已跳过，开始下一段专注');
  }
  
  /**
   * 重置引擎状态到空闲。
   */
  reset(): void {
    this.cleanupTimer();
    this.resetState();
    
    console.log('引擎已重置');
  }
  
  // todos
  
  /**
   * 同步到实况窗。
   * TODO: [扩展预留] 后续实现实况窗联动
   */
  syncToLiveWindow(): void {
    // TODO: [扩展预留] 实现实况窗同步逻辑
    console.log('实况窗同步（预留接口）');
  }
  
  /**
   * 后台计时接口。
   * TODO: [扩展预留] 后续实现后台任务
   */
  startBackgroundTimer(): Promise<void> {
    // TODO: [扩展预留] 实现后台计时逻辑
    console.log('后台计时（预留接口）');
    return Promise.resolve();
  }
  
  // ===== 私有方法 =====
  
  /** 启动计时器 */
  private startTimer(): void {
    this.cleanupTimer(); // 清理可能存在的旧计时器
    
    this.timerId = setInterval(() => {
      this.tick();
    }, 1000);
  }
  
  /** 计时器回调*/
  private tick(): void {
    const now = Date.now();
    
    if (this.expectedEndTime > 0) {
      // 使用时间戳校准逻辑：计算基于预期结束时间的剩余时间
      const remainingMs = Math.max(0, this.expectedEndTime - now);
      const elapsedSeconds = Math.floor((now - this.startTimestamp) / 1000);
      this.remainingSeconds = Math.ceil(remainingMs / 1000);
      
      // 检查是否完成
      if (remainingMs <= 0) {
        console.log(`tick: 阶段完成，state=${this.state}, remainingMs=${remainingMs}, expectedEndTime=${this.expectedEndTime}`);
        this.onStageComplete();
      } else {
        //console.log(`tick: 倒计时中，state=${this.state}, remainingSeconds=${this.remainingSeconds}, remainingMs=${remainingMs}`);
      }
    } else {
      // 回退到原始逻辑（当expectedEndTime未设置时）
      const elapsedSeconds = Math.floor((now - this.startTimestamp) / 1000);
      
      if (elapsedSeconds >= this.totalSeconds) {
        // 当前阶段完成
        console.log(`tick: 阶段完成（无expectedEndTime），state=${this.state}, elapsedSeconds=${elapsedSeconds}, totalSeconds=${this.totalSeconds}`);
        this.onStageComplete();
      } else {
        this.remainingSeconds = this.totalSeconds - elapsedSeconds;
      }
    }
  }
  
  /** 当前阶段完成处理 */
  private onStageComplete(): void {
    this.cleanupTimer();
    this.remainingSeconds = 0;
    
    if (this.state === FocusState.WORKING) {
      // 工作阶段完成，进入休息
      this.onWorkComplete();
    } else if (this.state === FocusState.RESTING) {
      // 休息阶段完成，停止专注
      this.onRestComplete();
    }
  }
  
  /** 工作阶段完成处理 */
  private onWorkComplete(): void {
    console.log('工作阶段完成，开始休息');
    console.log(`设置休息阶段：总时间${this.DefaultRestDuration}秒，预期结束时间${this.startTimestamp + (this.DefaultRestDuration * 1000)}`);
    // 通知
    this.sendCompletionNotification('专注完成', '恭喜完成一段专注时间！开始休息。');
    // 在进入休息前，只要elapsedSeconds > 0，就立刻保存记录
    if (this.elapsedSeconds > 0) {
      this.saveFocusRecord();
    }
    // 进入休息阶段
    this.totalSeconds = this.DefaultRestDuration;
    this.remainingSeconds = this.DefaultRestDuration;
    this.startTimestamp = Date.now();
    this.expectedEndTime = this.startTimestamp + (this.totalSeconds * 1000); // 修复：设置预期结束时间
    this.state = FocusState.RESTING;
    console.log(`休息阶段状态：state=${this.state}, isCounting=${this.isCounting}, expectedEndTime=${this.expectedEndTime}`);
    this.startTimer();
  }
  
  /** 休息阶段完成处理 */
  private onRestComplete(): void {
    console.log('休息阶段完成');
    
    // 发送完成通知
    this.sendCompletionNotification('休息完成', '休息时间结束，自动开始下一段专注！');
    
    // 自动重启专注（实现自动循环逻辑）
    this.cleanupTimer(); // 清理休息计时器
    this.start(this.currentWorkDuration, this.todoId); // 使用当前工作时长自动重启
    
    console.log('自动开始下一段专注');
  }
  
  /** 发送完成通知 */
  private sendCompletionNotification(title: string, content: string): void {
    // 调用现有的NotificationService
    // TODO: 替换为实际的通知调用
    console.log(`发送通知：${title} - ${content}`);
    
    // 预留NotificationService调用
    // const notificationService = new NotificationService();
    // notificationService.sendFocusCompletionNotification(title, content);
  }
  
  /** 保存专注记录 */
  private saveFocusRecord(): void {
    // TODO: [扩展预留] 实现专注记录保存
    console.log(`保存专注记录：${this.focusRecordId}，时长：${this.elapsedSeconds}秒`);
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
    this.remainingSeconds = this.currentWorkDuration; // 使用当前工作时长（修复自定义时长丢失问题）
    this.totalSeconds = this.currentWorkDuration;
    this.todoId = '';
    this.focusRecordId = '';
    this.startTimestamp = 0;
    this.expectedEndTime = 0; // 修复：重置预期结束时间
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
    switch (this.state) {
      case FocusState.WORKING:
        return '专注中';
      case FocusState.PAUSED:
        return '已暂停';
      case FocusState.RESTING:
        return '休息中';
      default:
        return '空闲';
    }
  }
  
  /** 检查是否关联了待办 */
  hasTodo(): boolean {
    return !!this.todoId && this.todoId.trim() !== '';
  }
}
