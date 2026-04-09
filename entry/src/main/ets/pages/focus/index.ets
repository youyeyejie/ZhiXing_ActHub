import { FocusTimerPanel } from './components/FocusTimerPanel';
import { TodoPickerSheet } from './components/TodoPickerSheet';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 专注模块主页，组合计时面板与待办选择测试组件。
 * - TODO: 尚未接入完整专注状态机、实况窗与白噪音控制。
 *
 * 可传入项：
 * - @Param onRequestDismiss: 顶部下拉按钮触发时请求关闭专注页。
 *
 * 返回行为：
 * - 返回全屏专注布局并渲染专注相关子组件。
 *
 * 副作用：
 * - 关闭按钮会触发上层 overlay 关闭流程。
 */
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  @Param onRequestDismiss: () => void = () => {};

  /**
   * 渲染专注页骨架。
   * TODO: 当前仅包含基础容器与测试文案，未接入完整专注流程。
   */
  build() {
    Column() {
      Row(){
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
      

      Text("此页面目前组件均为测试，需要修改！")
      Text('TODO: 在开始前选择待办或直接进入计时。')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary);

      FocusTimerPanel();
      TodoPickerSheet();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
