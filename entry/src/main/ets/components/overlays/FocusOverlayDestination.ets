import display from '@ohos.display';
import { AppState, useAppState } from '../../app/AppStates';
import { FocusPage } from '../../pages/focus';
import { StatusBarService } from '../../core/services/StatusBarService';
import { SafeAreaInsetLayout } from '../layout/SafeAreaInsetLayout';

/**
 * 组件功能简介：
 * - 专注页 overlay 路由容器，负责页面滑入滑出动画和状态栏显隐控制。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回对话式目的页容器并渲染 FocusPage。
 *
 * 副作用：
 * - 会在入场后隐藏状态栏、关闭前恢复状态栏。
 * - 会管理入场/出场计时器并在关闭后调用 `app.nav.back(false)`。
 */
@ComponentV2
export struct FocusOverlayDestination {
  @Local private app: AppState = useAppState();
  @Local private statusBarHidden: boolean = false;
  @Local private panelOffsetY: number = 1200;
  @Local private panelTravelY: number = 1200;
  @Local private closing: boolean = false;
  @Local private entered: boolean = false;
  private enterDoneTimerId: number = -1;
  private dismissDoneTimerId: number = -1;
  private enterDuration: number = 300;
  private exitDuration: number = 200;

  aboutToAppear(): void {
    this.clearEnterDoneTimer();
    this.clearDismissDoneTimer();
    this.panelTravelY = this.resolveOffscreenOffset();
    this.panelOffsetY = this.panelTravelY;
    this.closing = false;
    this.entered = false;
    setTimeout(() => {
      this.startEnterAnimation();
    }, 16);
  }

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
    this.clearEnterDoneTimer();
    this.clearDismissDoneTimer();
    this.restoreStatusBarBeforeDismiss();
  }

  private clearEnterDoneTimer(): void {
    if (this.enterDoneTimerId >= 0) {
      clearTimeout(this.enterDoneTimerId);
      this.enterDoneTimerId = -1;
    }
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
    this.clearEnterDoneTimer();
    this.enterDoneTimerId = setTimeout(() => {
      if (!this.closing) {
        this.hideStatusBarAfterEnter();
      }
      this.enterDoneTimerId = -1;
    }, this.enterDuration);
  }

  private requestDismiss(): void {
    if (this.closing) {
      return;
    }
    this.clearEnterDoneTimer();
    this.clearDismissDoneTimer();
    this.restoreStatusBarBeforeDismiss();
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
          includeTop: true,
          surfaceColor: this.app.theme.palette.background,
        }) {
          FocusPage({
            onRequestDismiss: () => {
              this.requestDismiss();
            },
          });
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
