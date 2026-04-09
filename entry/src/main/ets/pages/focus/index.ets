import { FocusTimerPanel } from './components/FocusTimerPanel';
import { TodoPickerSheet } from './components/TodoPickerSheet';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 专注模块主页骨架。
 * TODO: 后续接入全屏沉浸式布局、实况窗联动和白噪音控制。
 */
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  @Param onRequestDismiss: () => void = () => {};

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
