import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';

/**
 * 专注模块沉浸式页面
 * Question：目前把focusEngine在这里实例化了，但是为了页面隐藏的时候计时也能进行，或许需要在AppStates中实例化
 * 为了测试番茄钟时间暂时改成了30s
 */
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  @Param onRequestDismiss: () => void = () => {};
  // tmp：暂时本地实例化FocusTimerEngine
  @Local private engine: FocusTimerEngine = new FocusTimerEngine();

  build() {
    Column() {
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(24)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([this.app.theme.palette.textPrimary])
          }
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .backgroundColor(this.app.theme.palette.surface)
          .onClick(() => {
            // TODO: 引擎提升至全局后，删除此处的 cleanupTimer，改为只解除 UI 绑定。
            // tmp：清理计时器防止内存泄漏
            this.engine.cleanupTimer();
            this.onRequestDismiss();
          })

          .margin({ left: 16, top: 16 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);

      // 内容区域
      Column({ space: 0 }) {
        // 任务选择器
        FocusTaskSelector({ engine: this.engine })
          .margin({ top: 5 })

        // 计时显示组件
        FocusTimerDisplay({ engine: this.engine })
          .margin({ top: 40 })
        
        FocusControlButtons({ engine: this.engine })
          .margin({ top: 20 })

        // 激励文字
        // todo: customize ?
        Text('"保持专注，心无旁骛"')
          .fontSize(18)
          .fontColor(this.app.theme.palette.textTertiary)
          .textAlign(TextAlign.Center)
          .margin({ top: 60 })
      }
      .width('100%')
      .layoutWeight(1) // 占据剩余空间
      .justifyContent(FlexAlign.Center) // 居中显示
      .alignItems(HorizontalAlign.Center) // 水平居中
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .padding({ top: 16 }); // 添加顶部padding避免状态栏遮挡
  }
}
