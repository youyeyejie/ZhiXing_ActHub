import display from '@ohos.display';
import { SearchRouteParam } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { SearchPage } from '../../pages/search';
import { SafeAreaInsetLayout } from '../layout/SafeAreaInsetLayout';

@ComponentV2
export struct SearchOverlayDestination {
  @Local private app: AppState = useAppState();
  @Param routeParam: SearchRouteParam = new SearchRouteParam('', '搜索');
  @Local private panelOffsetY: number = 1200;
  @Local private panelTravelY: number = 1200;
  @Local private closing: boolean = false;
  @Local private entered: boolean = false;
  private dismissDoneTimerId: number = -1;
  private enterDuration: number = 300;
  private exitDuration: number = 200;

  aboutToAppear(): void {
    this.clearDismissDoneTimer();
    this.panelTravelY = this.resolveOffscreenOffset();
    this.panelOffsetY = this.panelTravelY;
    this.closing = false;
    this.entered = false;
    setTimeout(() => {
      this.startEnterAnimation();
    }, 16);
  }

  aboutToDisappear(): void {
    this.clearDismissDoneTimer();
  }

  private clearDismissDoneTimer(): void {
    if (this.dismissDoneTimerId >= 0) {
      clearTimeout(this.dismissDoneTimerId);
      this.dismissDoneTimerId = -1;
    }
  }

  private resolveOffscreenOffset(): number {
    try {
      const info = display.getDefaultDisplaySync();
      return Math.max(info.width, info.height);
    } catch (_error) {
      return 1200;
    }
  }

  private startEnterAnimation(): void {
    if (this.entered) {
      return;
    }
    this.entered = true;
    this.panelOffsetY = 0;
  }

  private requestDismiss(): void {
    if (this.closing) {
      return;
    }
    this.clearDismissDoneTimer();
    this.closing = true;
    this.panelOffsetY = this.panelTravelY;
    this.dismissDoneTimerId = setTimeout(() => {
      this.dismissDoneTimerId = -1;
      this.closing = false;
      this.app.nav.back(false);
    }, this.exitDuration);
  }

  build() {
    NavDestination() {
      Column() {
        SafeAreaInsetLayout({
          includeTop: false,
          surfaceColor: this.app.theme.palette.background,
        }) {
          SearchPage({
            routeParam: this.routeParam,
            onRequestDismiss: () => {
              this.requestDismiss();
            },
          })
        }
      }
      .width('100%')
      .height('100%')
      .translate({ x: 0, y: this.panelOffsetY })
      .animation({
        duration: this.closing ? this.exitDuration : this.enterDuration,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal,
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .mode(NavDestinationMode.DIALOG)
    .onBackPressed(() => {
      this.requestDismiss();
      return true;
    });
  }
}
