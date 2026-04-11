import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';

/**
 * 组件功能简介：
 * - 专注模块主容器页面，采用沉浸式全屏
 * - TODO: 当前计时引擎为组件内局部实例化，会随着组件一起销毁
 * - Question：后续应该把AppEngine挂载至全局 AppState？
 *
 * 可传入项：
 * - @Param onRequestDismiss: () => void 顶部关闭按钮触发的回调函数，用于通知外层 Overlay 容器执行平滑退出动画与路由出栈。
 *
 * 返回行为：
 * - 渲染完整的沉浸式专注页面，包含返回控制、核心计时交互区及底部激励语。
 *
 * 副作用：
 * - 触发 onRequestDismiss 会切断当前视图与外层 Overlay 的联系。
 * - [临时副作用]: 当前点击关闭时，会主动调用 engine.cleanupTimer() 清理计时器以防止内存泄漏。待引擎提升至全局后需剥离此清理逻辑。
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
