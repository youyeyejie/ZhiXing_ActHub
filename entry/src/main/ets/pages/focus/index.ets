import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';

/**
 * 专注模块沉浸式页面
 * 问题1：为了沉浸感没有用mainTabPageLayout，是否需要和其他页面统一？
 * 问题2：目前把focusEngine在这里实例化了，但是为了页面隐藏的时候计时也能进行，或许需要在AppStates中实例化
 */
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  
  // tmp：暂时本地实例化FocusTimerEngine
  @Local private engine: FocusTimerEngine = new FocusTimerEngine();

  aboutToDisappear() {
    // TODO: 引擎提升至全局后，删除此处的 cleanupTimer，改为只解除 UI 绑定。
    // tmp：清理计时器防止内存泄漏
    this.engine.cleanupTimer();
  }

  /**
   * 渲染专注页骨架。
   * TODO: 当前仅包含基础容器与测试文案，未接入完整专注流程。
   */
  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Text() {
            SymbolSpan($r('sys.symbol.chevron_down'))
            .fontWeight(FontWeight.Normal)
            .fontSize(40)
            .fontColor([this.app.theme.palette.textPrimary])
          }
        }
        .width(88)
        .height(88)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 点击关闭按钮，调用AppNav.back()隐藏页面
          console.log('关闭专注页面，返回主界面');
          // TODO: 调用 AppNav.back()
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Top)
      .padding({
        top: SafeAreaUtils.getTopInset() + 10,
        right: 20,
        bottom: 2,
        left: 2
      })
      .backgroundColor(this.app.theme.palette.background)
      .zIndex(1)
    
      Column({ space: 0 }) {
        // 任务选择器
        FocusTaskSelector({ engine: this.engine })
          .margin({ top: 20 })

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
      .justifyContent(FlexAlign.Start) // 顶部对齐
      .alignItems(HorizontalAlign.Center) // 水平居中
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .expandSafeArea([SafeAreaType.KEYBOARD]);
  }
}
