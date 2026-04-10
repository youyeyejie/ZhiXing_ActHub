import { NotificationService } from './NotificationService';

/**
 * 专注状态枚举。
 * 定义番茄钟工作法的不同阶段。
 */
export enum FocusState {
  IDLE = 'idle',          // 空闲状态
  WORKING = 'working',    // 工作中（专注阶段）
  PAUSED = 'paused',      // 已暂停
  RESTING = 'resting',    // 休息中
}

/**
 * 专注计时引擎。
 * 使用 @ObservedV2 装饰器实现响应式状态管理。
 * 负责番茄钟状态机、计时逻辑和专注记录创建。
 */
@ObservedV2
export class FocusTimerEngine {
  // ===== 状态属性 =====
  
  /** 当前专注状态 */
  @Trace state: FocusState = FocusState.IDLE;
  
  /** 当前剩余时间（秒） */
  @Trace remainingSeconds: number = 0;
  
  /** 当前阶段总时间（秒） */
  @Trace totalSeconds: number = 0;
  
  /** 关联的待办ID */
  @Trace todoId: string = '';
  
  /** 专注记录ID（创建后填充） */
  @Trace focusRecordId: string = '';
  
  /** 是否正在倒计时 */
  @Trace isCounting: boolean = false;
  
  // ===== 配置属性 =====
  
  /** 专注工作时间（秒），默认25分钟 */
  workDuration: number = 25 * 60;
  
  /** 休息时间（秒），默认5分钟 */
  restDuration: number = 5 * 60;
  
  // ===== 私有属性 =====
  
  /** 计时器ID */
  private timerId: number = -1;
  
  /** 开始时间戳（毫秒） */
  private startTimestamp: number = 0;
  
  /** 已过去的时间（秒） */
  private elapsedSeconds: number = 0;
  
  /** 专注仓储实例（通过依赖注入） */
  private focusRepository: any = null; // TODO: 替换为具体的FocusRepository类型
  
  // ===== 生命周期方法 =====
  
  /**
   * 启动一次专注计时。
   * @param duration 可选的自定义专注时间（秒），默认使用workDuration
   * @param todoId 关联的待办ID，可选
   */
  start(duration?: number, todoId?: string): void {
    if (this.state !== FocusState.IDLE && this.state !== FocusState.RESTING) {
      console.warn('无法在非空闲/休息状态下启动专注');
      return;
    }
    
    // 设置参数
    this.todoId = todoId || '';
    this.totalSeconds = duration || this.workDuration;
    this.remainingSeconds = this.totalSeconds;
    this.elapsedSeconds = 0;
    this.startTimestamp = Date.now();
    this.state = FocusState.WORKING;
    this.isCounting = true;
    
    // 创建专注记录（暂不保存，专注完成时保存）
    this.focusRecordId = this.generateRecordId();
    
    // 启动计时器
    this.startTimer();
    
    console.log(`专注启动：${this.totalSeconds}秒，关联待办：${this.todoId || '无'}`);
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
    
    this.isCounting = false;
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
    this.isCounting = true;
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
    
    // 保存专注记录（如果专注已完成）
    if (saveRecord && this.elapsedSeconds > 0) {
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
    this.start(this.workDuration, this.todoId);
    
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
  
  // ===== 扩展功能预留接口 =====
  
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
  
  /** 计时器回调（每秒执行） */
  private tick(): void {
    const now = Date.now();
    this.elapsedSeconds = Math.floor((now - this.startTimestamp) / 1000);
    
    if (this.elapsedSeconds >= this.totalSeconds) {
      // 当前阶段完成
      this.onStageComplete();
    } else {
      this.remainingSeconds = this.totalSeconds - this.elapsedSeconds;
    }
  }
  
  /** 当前阶段完成处理 */
  private onStageComplete(): void {
    this.cleanupTimer();
    this.elapsedSeconds = this.totalSeconds;
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
    
    // 发送完成通知
    this.sendCompletionNotification('专注完成', '恭喜完成一段专注时间！开始休息。');
    
    // 进入休息阶段
    this.totalSeconds = this.restDuration;
    this.remainingSeconds = this.restDuration;
    this.elapsedSeconds = 0;
    this.startTimestamp = Date.now();
    this.state = FocusState.RESTING;
    this.isCounting = true;
    
    this.startTimer();
  }
  
  /** 休息阶段完成处理 */
  private onRestComplete(): void {
    console.log('休息阶段完成');
    
    // 发送完成通知
    this.sendCompletionNotification('休息完成', '休息时间结束，准备好开始下一段专注了吗？');
    
    // 停止专注并保存记录
    this.stop(true);
  }
  
  /** 发送完成通知 */
  private sendCompletionNotification(title: string, content: string): void {
    // 调用现有的NotificationService
    // TODO: [扩展预留] 替换为实际的通知调用
    console.log(`发送通知：${title} - ${content}`);
    
    // 预留NotificationService调用
    // const notificationService = new NotificationService();
    // notificationService.sendFocusCompletionNotification(title, content);
  }
  
  /** 保存专注记录 */
  private saveFocusRecord(): void {
    // TODO: [扩展预留] 实现专注记录保存逻辑
    console.log(`保存专注记录：${this.focusRecordId}，时长：${this.elapsedSeconds}秒`);
    
    // 预留FocusRepository调用
    // if (this.focusRepository) {
    //   const focusRecord = new Focus();
    //   focusRecord.id = this.focusRecordId;
    //   focusRecord.todoId = this.todoId;
    //   focusRecord.duration = this.elapsedSeconds;
    //   focusRecord.startTime = this.startTimestamp;
    //   focusRecord.endTime = Date.now();
    //   focusRecord.timestamp = Date.now();
    //   this.focusRepository.save(focusRecord);
    // }
  }
  
  /** 生成记录ID */
  private generateRecordId(): string {
    return `focus_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /** 清理计时器 */
  private cleanupTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.isCounting = false;
  }
  
  /** 重置状态 */
  private resetState(): void {
    this.state = FocusState.IDLE;
    this.remainingSeconds = 0;
    this.totalSeconds = this.workDuration;
    this.todoId = '';
    this.focusRecordId = '';
    this.elapsedSeconds = 0;
    this.startTimestamp = 0;
    this.isCounting = false;
  }
  
  // ===== 工具方法 =====
  
  /** 获取格式化剩余时间（MM:SS） */
  getFormattedRemainingTime(): string {
    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }
  
  /** 获取进度百分比（0-1） */
  getProgressPercentage(): number {
    if (this.totalSeconds <= 0) return 0;
    return this.elapsedSeconds / this.totalSeconds;
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
