import { HitokotoCard } from './components/HitokotoCard';
import { IdeaCard } from './components/IdeaCard';
import { IdeaEditorSheet } from './components/IdeaEditorSheet';
import { ActivityHeatmap } from './components/ActivityHeatmap';
import { CircleButton } from '../../components/buttons/CircleButton';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 闪记模块主页骨架。
 * TODO: 后续接入搜索遮罩、单列流式列表和详情卡片。
 */
@ComponentV2
export struct IdeaPage {
  @Local private app: AppState = useAppState();

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Text('闪记')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1);

          Blank();

          CircleButton({
              icon: '?',
              text: '搜索',
              buttonSize: 46,
              fillColor: this.app.theme.palette.primary,
              onTap: () => {
                this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('idea', '搜索闪记'));
              }
            });
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);
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
    .backgroundColor(this.app.theme.palette.background);
  }
}
