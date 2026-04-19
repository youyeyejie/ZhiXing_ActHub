import { AppState, useAppState } from '../../../app/AppStates';
import { common } from '@kit.AbilityKit';
import { PlayerState } from '../../../core/services/WhiteNoisePlayer';

/**
 * 组件功能简介：
 * - 白噪音选择卡片组件，提供曲目切换与播放中无缝换曲能力。
 *
 * 可传入项：
 * - 无（通过 `AppState` 读取与更新播放器状态）。
 *
 * 返回行为：
 * - 渲染白噪音列表并高亮当前选中项。
 *
 * 副作用：
 * - 点击会更新选中曲目，播放中会触发重新播放。
 */
@ComponentV2
export struct WhiteNoiseSelectorCard {
  @Local private app: AppState = useAppState();

  private isNoiseSelected(file: string): boolean {
    return this.app.whiteNoisePlayer.selectedTrack === file;
  }

  @Builder
  private buildNoiseItem(name: string, file: string, icon: Resource) {
    Row({ space: 16 }) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.isNoiseSelected(file) ? this.app.theme.palette.primary : this.app.theme.palette.textPrimary])
        
      Text(name)
        .fontSize(16)
        .fontColor(this.isNoiseSelected(file) ? this.app.theme.palette.primary : this.app.theme.palette.textPrimary)
        .layoutWeight(1)

      if (this.isNoiseSelected(file)) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(20)
          .fontColor([this.app.theme.palette.primary])
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isNoiseSelected(file) ? this.app.theme.palette.surfaceSecondary : this.app.theme.palette.transparent)
    .borderRadius(12)
    .onClick(() => {
      if (this.isNoiseSelected(file)) return; // 必选其一，不允许取消

      this.app.whiteNoisePlayer.selectedTrack = file;
      
      if (this.app.whiteNoisePlayer.state === PlayerState.PLAYING) {
        const context = getContext(this) as common.UIAbilityContext;
        this.app.whiteNoisePlayer.playWhiteNoise(context, file); // 播放中无缝切歌
      }
    })
  }

  build() {
    Column() {
      // 标题与关闭按钮
      Row() {
        Text('选择白噪音')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 })

      // 列表项
      Column({ space: 8 }) {
        this.buildNoiseItem('雨声', 'rain.mp3', $r('sys.symbol.icloud'))
        this.buildNoiseItem('流水', 'water.mp3', $r('sys.symbol.drop'))
        this.buildNoiseItem('海浪', 'sea.mp3', $r('sys.symbol.music'))
      }
      .width('100%')
    }
    .width('100%')
  }
}