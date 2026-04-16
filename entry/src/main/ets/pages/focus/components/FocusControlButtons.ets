/**
 * 组件功能简介：
 * - 专注控制按钮组，提供专注计时启停、结束操作，并集成了白噪音快捷播放与长按轨道选择。
 *
 * 可传入项：
 * - @Param customDuration: number (专注工作时长)
 * - @Param customRestDuration: number (专注休息时长)
 * - @Event goBackIndex: () => void (返回首页回调)
 *
 * 返回行为：
 * - 渲染包含三个圆形按钮的控制条（白噪音开关、播放/暂停、停止），长按白噪音按钮弹出音轨选择器。
 *
 * 副作用：
 * - 启停或重置内部的 FocusTimerEngine。
 * - 调用 WhiteNoisePlayer 进行音频状态流转（播放、暂停），并更新当前选中的音轨资源。
 * - 触发 AppNav 打开 DetailCard 覆盖页。
 */
import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';
import { PlayerState } from '../../../core/services/WhiteNoisePlayer'; 
import { common } from '@kit.AbilityKit'; 

@ComponentV2
export struct FocusControlButtons {
  @Local private app: AppState = useAppState();
  @Require @Param customDuration: number;
  @Require @Param customRestDuration: number;
  @Event goBackIndex: () => void = () => {};

  get engine(): FocusTimerEngine {
    return this.app.focusEngine;
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
    if (player.state === PlayerState.PLAYING) {
      player.pause();
    } else if (player.state === PlayerState.PAUSED) {
      player.resume();
    } else {
      const context = getContext(this) as common.UIAbilityContext;
      player.playWhiteNoise(context, player.selectedTrack);
    }
  }

  @Builder
  private buildNoiseItem(name: string, file: string, icon: Resource) {
    Row({ space: 16 }) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.app.theme.palette.primary])
        
      Text(name)
        .fontSize(16)
        .fontColor(this.app.theme.palette.textPrimary)
        .layoutWeight(1)

      // 选中的打个勾
      if (this.app.whiteNoisePlayer.selectedTrack === file) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(20)
          .fontColor([this.app.theme.palette.primary])
      }
    }
    .width('100%')
    .padding(16)
    // 选中的高亮背景
    .backgroundColor(this.app.whiteNoisePlayer.selectedTrack === file ? this.app.theme.palette.surfaceSecondary : Color.Transparent)
    .borderRadius(12)
    .onClick(() => {
      this.app.whiteNoisePlayer.selectedTrack = file;
      const context = getContext(this) as common.UIAbilityContext;
      this.app.whiteNoisePlayer.playWhiteNoise(context, file);
      this.app.nav.back(false);
    })
  }

  @Builder
  private buildNoiseSelector() {
    Column({ space: 8 }) {
      this.buildNoiseItem('雨声', 'rain.mp3', $r('sys.symbol.icloud'))
      this.buildNoiseItem('流水', 'water.mp3', $r('sys.symbol.drop'))
      this.buildNoiseItem('海浪', 'sea.mp3', $r('sys.symbol.music'))
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
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
        this.handleWhiteNoiseClick(); // 单击控制启停
      })
      // 长按手势呼出detailcard
      .gesture(
        LongPressGesture({ repeat: false, duration: 400 })
          .onAction(() => {
            this.app.nav.openDetailCard(() => { this.buildNoiseSelector() });
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