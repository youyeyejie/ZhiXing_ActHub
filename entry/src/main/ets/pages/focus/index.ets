import { SafeAreaInsetLayout } from '../../components/layout/SafeAreaInsetLayout';
import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';

/**
 * 专注模块主页 - 组件拆分重构版。
 * 布局结构：
 * 1. 顶部：关闭按钮（安全区内部左上角）
 * 2. 中部：垂直居中显示三个拆分组件
 *    - FocusTaskSelector：任务选择器
 *    - FocusTimerDisplay：计时显示（始终正中央）
 *    - FocusControlButtons：控制按钮
 */
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  
  // 专注计时引擎实例（所有拆分组件共享）
  @Local private engine: FocusTimerEngine = new FocusTimerEngine();

  aboutToDisappear() {
    // TODO: [架构待沟通] 引擎提升至全局后，删除此处的 cleanupTimer，改为只解除 UI 绑定。
    // 临时方案：必须清理计时器防止内存泄漏，但会中断后台计时
    this.engine.cleanupTimer();
  }

  /**
   * 渲染专注页骨架。
   * TODO: 当前仅包含基础容器与测试文案，未接入完整专注流程。
   */
  build() {
    SafeAreaInsetLayout({
      includeTop: true,      // 包含顶部安全区
      includeBottom: true,   // 包含底部安全区
      extraTop: 0,           // 额外顶部偏移
      extraBottom: 0         // 额外底部偏移
    }) {
      Column() {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text() {
              SymbolSpan($r('sys.symbol.chevron_down'))
              .fontWeight(FontWeight.Normal)
              .fontSize(20)
              .fontColor([this.app.theme.palette.textPrimary])
            }
          }
          .width(44)
          .height(44)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            // 点击关闭按钮，调用AppNav.back()隐藏页面
            console.log('关闭专注页面，返回主界面');
            // TODO: 调用 AppNav.back()
          })
        }
        .width('100%')
        .padding({ left: 20, top: 20 })
        .justifyContent(FlexAlign.Start) // 左对齐

        // 2. 中部区域：垂直水平居中布局
        Column({ space: 40 }) {
          // 2.1 任务选择器
          FocusTaskSelector({ engine: this.engine })
          
          // 2.2 计时显示组件（始终位于正中央）
          FocusTimerDisplay({ engine: this.engine })
          
          // 2.3 控制按钮
          FocusControlButtons({ engine: this.engine })
        }
        .width('100%')
        .layoutWeight(1) // 占据剩余空间
        .justifyContent(FlexAlign.Center) // 垂直居中
        .alignItems(HorizontalAlign.Center) // 水平居中
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background);
    }
  }
}
