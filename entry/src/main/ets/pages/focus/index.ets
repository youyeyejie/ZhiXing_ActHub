import { FocusTimerPanel } from './components/FocusTimerPanel';
import { TodoPickerSheet } from './components/TodoPickerSheet';

/**
 * 专注模块主页骨架。
 * TODO: 后续接入全屏沉浸式布局、实况窗联动和白噪音控制。
 */
@ComponentV2
export struct FocusPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('专注')
          .fontSize(28)
          .fontWeight(FontWeight.Bold);
        Text('TODO: 在开始前选择待办或直接进入计时。')
          .fontSize(14)
          .fontColor('#666666');
        FocusTimerPanel();
        TodoPickerSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
