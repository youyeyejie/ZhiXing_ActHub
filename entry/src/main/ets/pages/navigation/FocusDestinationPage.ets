import { FocusPage } from '../focus';
import { AppState, useAppState } from '../../app/AppStates';
import { SafeAreaInsetLayout } from '../../components/layout/SafeAreaInsetLayout';
import { NavDialogOverlay, NavDialogOverlayController } from '../../components/overlays/NavDialogOverlay';

/**
 * 专注页路由容器。
 * 通过通用 nav overlay 容器承载专注模块，并复用统一的入场/退出动画。
 */
@ComponentV2
export struct FocusDestinationPage {
  @Local private app: AppState = useAppState();
  private overlayController: NavDialogOverlayController = new NavDialogOverlayController();

  build() {
    NavDialogOverlay({
      controller: this.overlayController,
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

@Builder
export function FocusDestinationPageBuilder(_name: string, _param: Object) {
  FocusDestinationPage();
}
