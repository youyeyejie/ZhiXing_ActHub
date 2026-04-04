import { HitokotoCard } from './components/HitokotoCard';
import { IdeaCard } from './components/IdeaCard';
import { IdeaEditorSheet } from './components/IdeaEditorSheet';
import { ActivityHeatmap } from './components/ActivityHeatmap';
import { CircleButton } from '../../components/buttons/CircleButton';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState } from '../../app/AppStates';

/**
 * 闪记模块主页骨架。
 * TODO: 后续接入搜索遮罩、单列流式列表和详情卡片。
 */
@ComponentV2
export struct IdeaPage {
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
        title: '闪记搜索',
        placeholder: '搜索闪记标题/内容',
        scope: SearchScope.Idea,
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
          Text('闪记')
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
        HitokotoCard();
        IdeaCard();
        ActivityHeatmap();
        IdeaEditorSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appState.theme.palette.background);
  }
}
