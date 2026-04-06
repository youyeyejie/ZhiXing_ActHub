import { FocusTimerPanel } from './components/FocusTimerPanel';
import { TodoPickerSheet } from './components/TodoPickerSheet';
import { CircleButton } from '../../components/buttons/CircleButton';
import { AppOverlayRoute } from '../../app/AppConstants';
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
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Text('专注')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.app.theme.palette.textPrimary)
              .layoutWeight(1);

            CircleButton({
              icon: '?',
              text: '搜索',
              buttonSize: 46,
              fillColor: this.app.theme.palette.primary,
              onTap: () => {
                this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('focus', '搜索专注'));
              }
            });
          }
          .width('100%');

          Text('TODO: 在开始前选择待办或直接进入计时。')
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary);

          FocusTimerPanel();
          TodoPickerSheet();
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, bottom: 20 });
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%');
  }
}
