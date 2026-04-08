import { SearchRouteParam } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { SearchPage } from '../../pages/search';
import { SafeAreaInsetLayout } from '../layout/SafeAreaInsetLayout';
import { NavDialogOverlay, NavDialogOverlayController } from './NavDialogOverlay';

@ComponentV2
export struct SearchOverlayDestination {
  @Local private app: AppState = useAppState();
  @Param routeParam: SearchRouteParam = new SearchRouteParam('', '搜索');
  private overlayController: NavDialogOverlayController = new NavDialogOverlayController();

  build() {
    NavDialogOverlay({
      controller: this.overlayController,
      onDismiss: () => {
        this.app.nav.back(false);
      },
    }) {
      SafeAreaInsetLayout({
        includeTop: false,
        surfaceColor: this.app.theme.palette.background,
      }) {
        SearchPage({
          routeParam: this.routeParam,
          dismissController: this.overlayController,
        })
      }
    };
  }
}
