import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';
import { CircleButton } from '../../components/buttons/CircleButton';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState } from '../../app/AppStates';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口、浮动新建按钮和详情弹层。
 */
@ComponentV2
export struct PlanPage {
  @Consumer('appState') appState: AppState = new AppState();
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
        .backgroundColor(this.appState.theme.palette.background);

      SearchOverlay({
        title: '日程搜索',
        placeholder: '搜索日程内容/地点/描述',
        scope: SearchScope.Plan,
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
          Text('日程')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.appState.theme.palette.textPrimary)
            .layoutWeight(1);

          CircleButton({
            icon: '?',
            text: '搜索',
            buttonSize: 46,
            fillColor: this.appState.theme.palette.primary,
            onTap: () => {
              this.searchDialogController.open();
            }
          });
        }
        .width('100%');
        WeekCalendar();
        TimelineView();
        PlanCard();
        PlanEditorSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appState.theme.palette.background);
  }
}
