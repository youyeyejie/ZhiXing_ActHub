import { FocusTimerPanel } from './components/FocusTimerPanel';
import { TodoPickerSheet } from './components/TodoPickerSheet';
import { CircleButton } from '../../components/buttons/CircleButton';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 专注模块主页骨架。
 * TODO: 后续接入全屏沉浸式布局、实况窗联动和白噪音控制。
 */
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  @Local private topInset: number = 56;

  private searchDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildSearchDialog,
    customStyle: true,
    autoCancel: false,
    alignment: DialogAlignment.Top
  });

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getSearchTopInset();
  }

  @Builder
  private buildSearchDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.app.theme.palette.background);

      SearchOverlay({
        title: '专注搜索',
        placeholder: '搜索专注记录/时长',
        scope: SearchScope.Focus,
        topInset: this.topInset,
        onDismiss: () => {
          this.searchDialogController.close();
        }
      });
    }
    .width('100%')
    .height('100%');
  }

  build() {
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
              this.searchDialogController.open();
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
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
