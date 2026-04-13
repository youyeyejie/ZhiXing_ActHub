import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';
import { TodoPickerSheet } from './components/TodoPickerSheet';
import { ActionSheetController } from '../../components/card/ActionSheet';

/**
 * 组件功能简介：
 * - 专注模块主容器页面，采用沉浸式全屏
 * - 当前计时引擎已挂载至全局 AppState，脱离页面生命周期独立运行
 *
 * 可传入项：
 * - @Param onRequestDismiss: () => void 顶部关闭按钮触发的回调函数，用于通知外层 Overlay 容器执行平滑退出动画与路由出栈。
 *
 * 返回行为：
 * - 渲染完整的沉浸式专注页面，包含返回控制、核心计时交互区及底部激励语。
 *
 * 副作用：
 * - 触发 onRequestDismiss 会切断当前视图与外层 Overlay 的联系。UI 绑定自动解除，计时器在后台继续运行。
 */
 
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  @Param onRequestDismiss: () => void = () => {};
  
  // <-- 修改：利用 getter 获取全局单例，保持下方代码 this.engine 的引用不需要修改
  get engine(): FocusTimerEngine {
    return this.app.focusEngine;
  }
  
  /** 控制TodoPickerSheet显示/隐藏 */
  @Local private isPickerVisible: boolean = false;
  
  /** ActionSheet控制器，用于控制TodoPickerSheet的显示/隐藏 */
  @Local private sheetController: ActionSheetController = new ActionSheetController();

  /** 打开待办选择器 */
  private openTodoPicker(): void {
    console.log('打开待办选择器');
    this.isPickerVisible = true;
  }

  /** 关闭待办选择器 */
  private closeTodoPicker(): void {
    this.isPickerVisible = false;
    console.log('关闭待办选择器');
  }

  build() {
    Stack() {
      // 主内容区域
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
              this.onRequestDismiss();
            })
            .margin({ left: 16, top: 16 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start);

        // 内容区域
        Column({ space: 0 }) {
          // 任务选择器 - 使用原生@Monitor监听，无需手动触发刷新
          FocusTaskSelector({ 
            engine: this.engine,
            onOpenPicker: () => {
              this.openTodoPicker();
            }
          })
            .margin({ top: 5 })

          // 计时显示组件
          FocusTimerDisplay({ engine: this.engine })
            .margin({ top: 40 })
          
          FocusControlButtons({ engine: this.engine })
            .margin({ top: 20 })

          // 激励文字
          Text('"保持专注，心无旁骛"')
            .fontSize(18)
            .fontColor(this.app.theme.palette.textTertiary)
            .textAlign(TextAlign.Center)
            .margin({ top: 60 })
        }
        .width('100%')
        .layoutWeight(1) 
        .justifyContent(FlexAlign.Center) 
        .alignItems(HorizontalAlign.Center) 
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background)
      .padding({ top: 16 });

      // 当需要显示时挂载TodoPickerSheet
      if (this.isPickerVisible) {
        TodoPickerSheet({ 
          engine: this.engine,
          controller: this.sheetController,
          onClose: () => {
            this.closeTodoPicker();
          }
        });
      }
    }
    .width('100%')
    .height('100%');
  }
}