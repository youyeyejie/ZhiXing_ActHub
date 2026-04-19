import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';
import { PlayerState } from '../../../core/services/WhiteNoisePlayer'; 
import { common } from '@kit.AbilityKit'; 
import { WhiteNoiseSelectorCard } from './WhiteNoiseSelectorCard';

/**
 * 组件功能简介：
 * - 专注页控制按钮组件，负责白噪音、开始/暂停与停止三类核心操作。
 *
 * 可传入项：
 * - `customDuration`：自定义专注时长（秒）。
 * - `customRestDuration`：自定义休息时长（秒）。
 * - `goBackIndex`：开始后返回主视图的回调。
 *
 * 返回行为：
 * - 渲染控制按钮区域并驱动专注引擎状态流转。
 *
 * 副作用：
 * - 会调用专注引擎与白噪音播放器，并可能打开详情弹层。
 */
@ComponentV2
export struct FocusControlButtons {
  @Local private app: AppState = useAppState();
  @Require @Param customDuration: number;
  @Require @Param customRestDuration: number;
  @Event goBackIndex: () => void = () => {};

  get engine(): FocusTimerEngine {
    return this.app.focusEngine;
  }

  // 干净利落的 Builder 挂载点
  @Builder
  private buildNoiseSelectorContent() {
    WhiteNoiseSelectorCard();
  }

  private getMusicButtonColor(): string {
    if (this.app.whiteNoisePlayer.state === PlayerState.PLAYING || 
        this.app.whiteNoisePlayer.state === PlayerState.LOADING) {
      return this.app.theme.palette.primary; 
    }
    return this.app.theme.palette.textTertiary; 
  }

  private handleWhiteNoiseClick(): void {
    const player = this.app.whiteNoisePlayer;
    const context = getContext(this) as common.UIAbilityContext;
    
    if (player.state === PlayerState.PLAYING) {
      player.pause();
    } else if (player.state === PlayerState.PAUSED) {
      if (player.selectedTrack !== player.currentTrackName) {
        player.playWhiteNoise(context, player.selectedTrack); // 切了歌就重新加载
      } else {
        player.resume(); // 没切歌就直接继续
      }
    } else {
      player.playWhiteNoise(context, player.selectedTrack);
    }
  }

  build() {
    Row({ space: 30 }) {
      // --- 白噪音按钮 ---
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
      .backgroundColor(this.getMusicButtonColor()) 
      .shadow(this.app.whiteNoisePlayer.state === PlayerState.PLAYING ? 
        { radius: 8, color: this.app.theme.palette.primaryShadowStrong, offsetY: 2 } : undefined)
      .onClick(() => {
        this.handleWhiteNoiseClick(); 
      })
      .gesture(
        LongPressGesture({ repeat: false, duration: 400 })
          .onAction(() => {
            // 直接传递引用，呼出弹层
            this.app.nav.openDetailCard(this.buildNoiseSelectorContent, 'auto');
          })
      )

      // --- 核心启停按钮 ---
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
      .shadow({ radius: 10, color: this.app.theme.palette.primaryShadowSoft, offsetX: 0, offsetY: 4 })
      .onClick(() => {
        this.handlePlayPauseClick();
      })

      // --- 停止按钮 ---
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
        if (this.app.whiteNoisePlayer.state !== PlayerState.IDLE) {
          this.app.whiteNoisePlayer.pause(); 
        }
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