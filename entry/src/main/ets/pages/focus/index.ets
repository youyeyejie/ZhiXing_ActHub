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

  build() {
    Column() {
      PageScrollLayout({
        paddingTop: 0,
        paddingBottom: 20
      }) {
        Row() {
          Text('专注')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1);
        }
        .width('100%');

        Text('TODO: 在开始前选择待办或直接进入计时。')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary);

        FocusTimerPanel();
        TodoPickerSheet();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
