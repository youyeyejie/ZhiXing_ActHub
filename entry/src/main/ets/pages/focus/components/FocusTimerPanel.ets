import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';

/**
 * 沉浸式专注计时面板组件。
 * 按照原型设计.html中的沉浸式番茄钟页面重构。
 * 集成 FocusTimerEngine 计时引擎，实现沉浸式番茄钟交互界面。
 * 
 * 布局结构：
 * 1. 顶部栏：左上角关闭按钮 + 当前专注任务显示
 * 2. 中部计时区：大圆环进度显示 + 剩余时间数字
 * 3. 底部控制区：三按钮布局（白噪音、开始/暂停、终止）
 * 
 * 技术规范：
 * - 所有颜色从 ThemePalette 获取，支持深浅色主题
 * - 所有图标使用鸿蒙 Symbol 图标库（$r('sys.symbol.*')）
 * - 布局尺寸参考原型设计（圆环238vp，按钮70vp/50vp）
 * - 使用系统 Progress 组件（ProgressType.Ring）
 * 
 * TODO: [架构待沟通] 配合"隐藏继续计时"需求，需向组长申请将此引擎提升至 AppState 全局单例。
 */
@ComponentV2
export struct FocusTimerPanel {
  @Local private app: AppState = useAppState();
  
  // TODO: [架构待沟通] 配合"隐藏继续计时"需求，需向组长申请将此引擎提升至 AppState 全局单例。
  // 当前临时方案：局部实例化引擎，组件销毁时清理计时器
  @Local private engine: FocusTimerEngine = new FocusTimerEngine();

  aboutToDisappear() {
    // TODO: [架构待沟通] 引擎提升至全局后，删除此处的 cleanupTimer，改为只解除 UI 绑定。
    // 临时方案：必须清理计时器防止内存泄漏，但会中断后台计时
    this.engine.cleanupTimer();
  }

  build() {
    Column({ space: 0 }) {
      // 1. 中部计时区：大圆环进度显示
      this.buildTimerArea()
      
      // 2. 底部控制区：三按钮布局
      this.buildControlArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background) // 沉浸式全屏背景色
    .padding({ top: 0, bottom: 80, left: 0, right: 0 }); // 修改：移除顶部padding，顶部栏已移至外部
  }

  // ===== 沉浸式UI构建方法 =====

  /**
   * 构建计时区：任务选择区域 + 大圆环进度显示 + 剩余时间数字
   * 参考原型设计.html第494-500行，任务选择区域下移至圆环上方
   */
  @Builder
  private buildTimerArea() {
    Column({ space: 0 }) {
      // 任务选择区域（圆角矩形框，位于圆环上方）
      Column({ space: 8 }) {
        if (this.engine.hasTodo()) {
          // 有关联待办时显示
          Text(`当前任务: TODO_ID_${this.engine.todoId.substring(0, 8)}`)
            .fontSize(16)
            .fontColor(this.app.theme.palette.textPrimary)
            .textAlign(TextAlign.Center)
        } else {
          // 无关联待办时显示提示（可点击选择）
          Row({ space: 8 }) {
            Text(){
              SymbolSpan($r('sys.symbol.bookmark'))
              .fontWeight(FontWeight.Normal)
              .fontSize(14)
              .fontColor([this.app.theme.palette.textSecondary])
            }
            Text('选择专注任务')
              .fontSize(16)
              .fontColor(this.app.theme.palette.textSecondary)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('80%')
      .padding({ top: 12, bottom: 12, left: 20, right: 20 })
      .backgroundColor(this.app.theme.palette.surface) // 使用surface背景色
      .borderRadius(12) // 圆角矩形
      .border({ width: 1, color: this.app.theme.palette.border }) // 细边框
      .onClick(() => {
        // 点击任务区域打开待办选择器
        console.log('打开待办选择器');
        // TODO: 打开 TodoPickerSheet
      })
      .margin({ bottom: 40 }) // 与圆环的间距

      // 大圆环进度显示（238vp × 238vp，参考原型设计）
      Stack({ alignContent: Alignment.Center }) {
        // 圆环进度组件 - 使用系统 Progress 组件 (ProgressType.Ring)
        Progress({
          value: this.engine.getElapsedSeconds(),
          total: this.engine.totalSeconds,
          type: ProgressType.Ring
        })
          .width(238)
          .height(238)
          .color(this.app.theme.palette.primary) // 从 ThemePalette 获取颜色
          .style({ strokeWidth: 20, enableSmoothEffect: true })

        // 中心时间显示（大数字，字体缩小）
        Column({ space: 4 }) {
          // 剩余时间 (MM:SS)，字体从72缩小到56
          Text(this.engine.getFormattedRemainingTime())
            .fontSize(56) // 修改：从72缩小到56
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .textAlign(TextAlign.Center)
            
          // 当前阶段名称
          Text(this.engine.getCurrentStageName())
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width(238)
      .height(238)
      .margin({ top: 0, bottom: 60 }) // 调整顶部间距

      // 鼓舞性文字
      Text('"保持专注，心无旁骛"')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textTertiary)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 40 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建控制区：三按钮布局（白噪音、开始/暂停、终止）
   * 参考原型设计.html第501-505行
   */
  @Builder
  private buildControlArea() {
    Row({ space: 30 }) {
      // 左侧：白噪音按钮（50vp × 50vp，预留功能）修改颜色与xmark按钮一致
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(){
          SymbolSpan($r('sys.symbol.music_fill'))
          .fontWeight(FontWeight.Normal)
          .fontSize(20)
          .fontColor([this.app.theme.palette.surface])
        }
      }
      .width(50)
      .height(50)
      .backgroundColor(this.app.theme.palette.textSecondary) // 修改：与xmark按钮颜色一致
      .onClick(() => {
        console.log('白噪音功能（预留）');
        // TODO: [扩展预留] 实现白噪音控制
      })

      // 中间：开始/暂停按钮（70vp × 70vp，最大）
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(){
          SymbolSpan(this.getPlayPauseIcon())
          .fontWeight(FontWeight.Normal)
          .fontSize(20)
          .fontColor([this.app.theme.palette.surface])
        }
      }
      .width(70)
      .height(70)
      .backgroundColor(this.app.theme.palette.primary)
      .shadow({ radius: 10, color: this.app.theme.palette.primary + '40', offsetX: 0, offsetY: 4 })
      .onClick(() => {
        this.handlePlayPauseClick();
      })

      // 右侧：终止按钮（50vp × 50vp）使用textSecondary颜色
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(){
          SymbolSpan($r('sys.symbol.xmark'))
          .fontWeight(FontWeight.Normal)
          .fontSize(20)
          .fontColor([this.app.theme.palette.surface])
        }
        
      }
      .width(50)
      .height(50)
      .backgroundColor(this.app.theme.palette.textSecondary)
      .onClick(() => {
        // 停止当前专注，保存记录
        this.engine.stop(true);
        console.log('专注已终止');
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 20 })
  }

  // ===== 原有工具方法（保留） =====

  /**
   * 构建阶段信息显示区域（保留，可能其他地方使用）
   */
  @Builder
  private buildStageInfo() {
    Column({ space: 8 }) {
      // 阶段名称
      Text(this.engine.getCurrentStageName())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.app.theme.palette.textPrimary)
        .textAlign(TextAlign.Center)

      // 关联待办显示
      if (this.engine.hasTodo()) {
        Text('关联待办: TODO_ID_' + this.engine.todoId.substring(0, 8))
          .fontSize(12)
          .fontColor(this.app.theme.palette.textSecondary)
          .textAlign(TextAlign.Center)
      } else {
        Text('未关联待办')
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
  }

  /**
   * 构建圆环进度显示（保留，可能其他地方使用）
   */
  @Builder
  private buildProgressRing() {
    Stack({ alignContent: Alignment.Center }) {
      // 圆环进度组件 - 使用系统 Progress 组件 (ProgressType.Ring)
      Progress({
        value: this.engine.getElapsedSeconds(),
        total: this.engine.totalSeconds,
        type: ProgressType.Ring
      })
        .width(280)
        .height(280)
        .color(this.app.theme.palette.primary) // 从 ThemePalette 获取颜色
        .style({ strokeWidth: 20, enableSmoothEffect: true })

      // 中心时间显示
      Column({ space: 4 }) {
        // 剩余时间 (MM:SS)
        Text(this.engine.getFormattedRemainingTime())
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.textPrimary)
          .textAlign(TextAlign.Center)

        // 进度百分比
        Text(`${Math.round(this.engine.getProgressPercentage() * 100)}%`)
          .fontSize(16)
          .fontColor(this.app.theme.palette.textSecondary)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width(280)
    .height(280)
    .margin({ top: 16, bottom: 24 })
  }

  /**
   * 构建控制按钮组（保留，可能其他地方使用）
   */
  @Builder
  private buildControlButtons() {
    Row({ space: 24 }) {
      // 开始/暂停按钮
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(){
          SymbolSpan(this.getPlayPauseIcon())
          .fontWeight(FontWeight.Normal)
          .fontSize(20)
          .fontColor([this.app.theme.palette.surface])
        }
      }
      .width(56)
      .height(56)
      .backgroundColor(this.app.theme.palette.primary)
      .onClick(() => {
        this.handlePlayPauseClick();
      })

      // 跳过休息按钮（仅在休息状态显示）
      if (this.engine.state === FocusState.RESTING) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text(){
            SymbolSpan($r('sys.symbol.chevron_forward'))
            .fontWeight(FontWeight.Normal)
            .fontSize(20)
            .fontColor([this.app.theme.palette.surface])
          }
        }
        .width(56)
        .height(56)
        .backgroundColor(this.app.theme.palette.textSecondary)
        .onClick(() => {
          this.engine.skipRest();
        })
      }

      // 重置按钮（仅在空闲或暂停状态显示）
      if (this.engine.state === FocusState.IDLE || this.engine.state === FocusState.PAUSED) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text(){
            SymbolSpan($r('sys.symbol.arrow_clockwise'))
            .fontWeight(FontWeight.Normal)
            .fontSize(20)
            .fontColor([this.app.theme.palette.surface])
          }
        }
        .width(56)
        .height(56)
        .backgroundColor(this.app.theme.palette.textTertiary)
        .onClick(() => {
          this.engine.reset();
        })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建状态信息区域（保留，可能其他地方使用）
   */
  @Builder
  private buildStatusInfo() {
    Column({ space: 12 }) {
      // 计时状态说明
      Text(this.getStatusDescription())
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 当前配置信息
      Row({ space: 16 }) {
        Text(`专注: ${this.engine.workDuration / 60}分钟`)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
        Text(`休息: ${this.engine.restDuration / 60}分钟`)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .width('100%')
    .margin({ top: 16 })
  }

  /**
   * 获取播放/暂停图标
   */
  private getPlayPauseIcon(): Resource {
    if (this.engine.state === FocusState.WORKING || this.engine.state === FocusState.RESTING) {
      // 工作中或休息中 -> 显示暂停图标
      return $r('sys.symbol.pause');
    } else {
      // 空闲或暂停 -> 显示播放图标
      return $r('sys.symbol.play_fill');
    }
  }

  /**
   * 处理播放/暂停点击
   */
  private handlePlayPauseClick(): void {
    switch (this.engine.state) {
      case FocusState.IDLE:
        // 空闲状态 -> 开始专注
        this.engine.start(30);
        break;
      case FocusState.WORKING:
      case FocusState.RESTING:
        // 工作中或休息中 -> 暂停
        this.engine.pause();
        break;
      case FocusState.PAUSED:
        // 已暂停 -> 恢复
        this.engine.resume();
        break;
    }
  }

  /**
   * 获取状态描述文本
   */
  private getStatusDescription(): string {
    switch (this.engine.state) {
      case FocusState.IDLE:
        return '准备开始专注。点击开始按钮启动25分钟番茄钟。';
      case FocusState.WORKING:
        return '专注工作中。请集中注意力完成任务，避免分心。';
      case FocusState.PAUSED:
        return '计时已暂停。点击继续按钮恢复计时。';
      case FocusState.RESTING:
        return '休息时间。放松一下，为下一段专注做好准备。';
      default:
        return '专注计时面板';
    }
  }
}
