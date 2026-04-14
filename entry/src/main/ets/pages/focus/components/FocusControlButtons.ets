import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';

/**
 * 专注控制按钮组件。
 * 包含白噪音、开始/暂停、终止三个控制按钮。
 * todo：
 * - 白噪音选择与播放逻辑
 */
@ComponentV2
export struct FocusControlButtons {
  @Local private app: AppState = useAppState();

  get engine(): FocusTimerEngine {
    return this.app.focusEngine;
  }

  build() {
    Row({ space: 30 }) {
      // 左侧：白噪音按钮（50vp × 50vp，预留功能）修改颜色与xmark按钮一致
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(){
          SymbolSpan($r('sys.symbol.music_fill'))
          .fontWeight(FontWeight.Bold)
          .fontSize(25)
          .fontColor([this.app.theme.palette.surface])
        }
      }
      .width(50)
      .height(50)
      .backgroundColor(this.app.theme.palette.textTertiary)
      .onClick(() => {
        console.log('白噪音功能（预留）');
        // TODO: [扩展预留] 实现白噪音控制
      })

      // 中间：开始/暂停按钮（70vp × 70vp，最大）
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(){
          SymbolSpan(this.getPlayPauseIcon())
          .fontWeight(FontWeight.Bold)
          .fontSize(35)
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
          .fontWeight(FontWeight.Bold)
          .fontSize(25)
          .fontColor([this.app.theme.palette.surface])
        }
        
      }
      .width(50)
      .height(50)
      .backgroundColor(this.app.theme.palette.textTertiary)
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
        // 空闲状态 -> 开始专注 (注：此处你原代码传了30秒作测试，我已保留)
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
}