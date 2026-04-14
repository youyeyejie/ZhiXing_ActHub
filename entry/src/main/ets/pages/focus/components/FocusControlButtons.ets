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
  // 接收外部设定的时间
  @Require @Param customDuration: number;
  @Require @Param customRestDuration: number;
  @Event goBackIndex: () => void = () => {};
  get engine(): FocusTimerEngine {
    return this.app.focusEngine;
  }

  build() {
    Row({ space: 30 }) {
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
        console.log('白噪音功能预留');
      })

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
        this.engine.stop(true);
        this.goBackIndex();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 20 })
  }

  private getPlayPauseIcon(): Resource {
    if (this.engine.state === FocusState.WORKING || this.engine.state === FocusState.RESTING) {
      return $r('sys.symbol.pause');
    } else {
      return $r('sys.symbol.play_fill');
    }
  }

  private handlePlayPauseClick(): void {
    switch (this.engine.state) {
      case FocusState.IDLE:
        const workToStart = this.customDuration > 0 ? this.customDuration : 60;
        const restToStart = this.customRestDuration > 0 ? this.customRestDuration : 300;
        console.warn(`[FocusStartButton] 专注开始，输入时间工作${workToStart},休息${restToStart}`);
        this.engine.start(workToStart, restToStart);
        this.goBackIndex();
        break;
      case FocusState.WORKING:
      case FocusState.RESTING:
        this.engine.pause();
        break;
      case FocusState.PAUSED:
        this.engine.resume();
        break;
    }
  }
}