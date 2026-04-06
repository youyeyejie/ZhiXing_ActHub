import { AppState, useAppState } from '../../app/AppStates';
import { SafeAreaInsetLayout } from '../../components/layout/SafeAreaInsetLayout';
import { ActionSheetController } from '../../components/overlays/ActionSheet';
import { DetailCardController } from '../../components/card/DetailCard';
import { SharedInteractionTestPage } from '../sharedtest';

/**
 * 共享测试页路由容器。
 * 通过 NavDestination 承载测试页，避免普通页面直接作为目的页时出现空白节点。
 */
@ComponentV2
export struct SharedTestDestinationPage {
  @Local private app: AppState = useAppState();
  @Local private actionSheetVisible: boolean = false;
  @Local private detailCardVisible: boolean = false;
  private actionSheetController: ActionSheetController = new ActionSheetController();
  private detailCardController: DetailCardController = new DetailCardController();

  build() {
    NavDestination() {
      SafeAreaInsetLayout({
        includeTop: true,
        surfaceColor: this.app.theme.palette.background
      }) {
        SharedInteractionTestPage({
          actionSheetVisible: this.actionSheetVisible,
          detailCardVisible: this.detailCardVisible,
          actionSheetController: this.actionSheetController,
          detailCardController: this.detailCardController,
          onOpenActionSheet: () => {
            this.actionSheetVisible = true;
          },
          onCloseActionSheet: () => {
            this.actionSheetVisible = false;
          },
          onOpenDetailCard: () => {
            this.detailCardVisible = true;
          },
          onCloseDetailCard: () => {
            this.detailCardVisible = false;
          }
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .onBackPressed(() => {
      if (this.detailCardVisible) {
        this.detailCardController.dismiss();
        return true;
      }
      if (this.actionSheetVisible) {
        this.actionSheetController.dismiss();
        return true;
      }
      this.app.nav.back();
      return true;
    });
  }
}

@Builder
export function SharedTestDestinationPageBuilder(_name: string, _param: Object) {
  SharedTestDestinationPage();
}
