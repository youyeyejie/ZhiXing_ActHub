import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';

/**
 * 专注模块主页 - 参照 MainTabPageLayout 布局风格重构版。
 * 布局结构：
 * 1. 顶部栏：参照 MainTabPageLayout，只包含关闭按钮（放在标题位置）
 * 2. 内容区域：垂直居中显示三个拆分组件
 *    - FocusTaskSelector：任务选择器
 *    - FocusTimerDisplay：计时显示（始终正中央）
 *    - FocusControlButtons：控制按钮
 * 
 * 沉浸式页面不需要标题、actionIcon等元素，仅保留关闭按钮。
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
    Column() {
      // 1. 顶部栏：关闭按钮放大四倍并加粗，位置更高，仅删除点击动画效果，保留点击事件
      Row() {
        // 关闭按钮放大四倍（44->88），加粗，放在最左侧
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Text() {
            SymbolSpan($r('sys.symbol.chevron_down'))
            .fontWeight(FontWeight.Bold) // 加粗
            .fontSize(40) // 放大四倍（20->40）
            .fontColor([this.app.theme.palette.textPrimary])
          }
        }
        .width(88) // 放大四倍（44->88）
        .height(88)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 点击关闭按钮，调用AppNav.back()隐藏页面
          console.log('关闭专注页面，返回主界面');
          // TODO: 调用 AppNav.back()
        })
      }
      .width('100%') // 确保Row占据全宽
      .justifyContent(FlexAlign.Start) // 水平方向左对齐
      .alignItems(VerticalAlign.Top) // 垂直方向顶部对齐
      .padding({
        top: SafeAreaUtils.getTopInset() + 10, // 进一步减少顶部padding，位置更高
        right: 20,
        bottom: 2, // 进一步减少底部padding
        left: 2 // 进一步减少左侧padding，更靠近边缘
      })
      .backgroundColor(this.app.theme.palette.background)
      .zIndex(1)
    
      // 2. 内容区域：整体上移，圆环不再固定在页面中央
      Column({ space: 0 }) {
        // 任务选择器
        FocusTaskSelector({ engine: this.engine })
          .margin({ top: 20 })

        // 计时显示组件（不再固定在正中央，整体上移）
        FocusTimerDisplay({ engine: this.engine })
          .margin({ top: 40 }) // 圆环与任务选择器的间距
        
        FocusControlButtons({ engine: this.engine })
          .margin({ top: 20 }) // 控制按钮与上方内容的间距

        // 激励文字（整体上移）
        Text('"保持专注，心无旁骛"')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textTertiary)
          .textAlign(TextAlign.Center)
          .margin({ top: 60 }) // 激励文字与圆环的间距
      }
      .width('100%')
      .layoutWeight(1) // 占据剩余空间
      .justifyContent(FlexAlign.Start) // 顶部对齐，不再垂直居中
      .alignItems(HorizontalAlign.Center) // 水平居中
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .expandSafeArea([SafeAreaType.KEYBOARD]); // 参照 MainTabPageLayout 的键盘安全区扩展
  }
}
