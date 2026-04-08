import { AppState, useAppState } from '../../app/AppStates';
import { ActionSheet, ActionSheetController } from '../card/ActionSheet';

@ComponentV2
export struct ActionSheetOverlayDestination {
  @Local private app: AppState = useAppState();
  private actionSheetController: ActionSheetController = new ActionSheetController();
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {}

  build() {
    NavDestination() {
      ActionSheet({
        isVisible: true,
        panelHeight: '56%',
        controller: this.actionSheetController,
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
      this.actionSheetController.dismiss();
      return true;
    });
  }
}
