import { AppState, useAppState } from '../../app/AppStates';
import { DetailCard, DetailCardController } from '../card/DetailCard';

@ComponentV2
export struct DetailCardOverlayDestination {
  @Local private app: AppState = useAppState();
  private detailCardController: DetailCardController = new DetailCardController();
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {}

  build() {
    NavDestination() {
      DetailCard({
        isVisible: true,
        controller: this.detailCardController,
        onDismiss: () => {
          this.app.nav.back(false);
        }
      }) {
        this.content();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .mode(NavDestinationMode.DIALOG)
    .onBackPressed(() => {
      this.detailCardController.dismiss();
      return true;
    });
  }
}
