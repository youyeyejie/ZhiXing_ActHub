import { AppState, useAppState } from '../../app/AppStates';
import { SearchRouteParam } from '../../app/AppConstants';
import { FocusPage } from '../../pages/focus';
import { SearchPage } from '../../pages/search';
import { StatusBarService } from '../../core/services/StatusBarService';
import { SafeAreaInsetLayout } from '../layout/SafeAreaInsetLayout';
import { NavDialogOverlay, NavDialogOverlayController } from '../navigation/NavDialogOverlay';

@ComponentV2
export struct FocusOverlayDestination {
  @Local private app: AppState = useAppState();
  @Local private statusBarHidden: boolean = false;
  private overlayController: NavDialogOverlayController = new NavDialogOverlayController();

  private hideStatusBarAfterEnter(): void {
    if (this.statusBarHidden) {
      return;
    }
    this.statusBarHidden = true;
    StatusBarService.hideStatusBar();
  }

  private restoreStatusBarBeforeDismiss(): void {
    if (!this.statusBarHidden) {
      return;
    }
    this.statusBarHidden = false;
    StatusBarService.showStatusBar();
  }

  aboutToDisappear(): void {
    this.restoreStatusBarBeforeDismiss();
  }

  build() {
    NavDialogOverlay({
      controller: this.overlayController,
      onWillDismiss: () => {
        this.restoreStatusBarBeforeDismiss();
      },
      onEnterAnimationEnd: () => {
        this.hideStatusBarAfterEnter();
      },
      onDismiss: () => {
        this.app.nav.back(false);
      }
    }) {
      SafeAreaInsetLayout({
        includeTop: true,
        surfaceColor: this.app.theme.palette.background
      }) {
        FocusPage();
      }
    }
  }
}

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
      }
    }) {
      SearchPage({
        routeParam: this.routeParam,
        dismissController: this.overlayController
      });
    }
  }
}
