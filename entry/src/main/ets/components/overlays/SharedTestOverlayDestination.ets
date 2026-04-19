import display from '@ohos.display';
import { AppState, useAppState } from '../../app/AppStates';
import { SharedInteractionTestPage } from '../../pages/sharedtest';

/**
 * 组件功能简介：
 * - 共享交互测试页 Overlay 路由容器，负责测试页的弹入弹出转场。
 *
 * 可传入项：
 * - 无（使用全局导航状态与内部关闭流程）。
 *
 * 返回行为：
 * - 渲染 `SharedInteractionTestPage` 并提供统一的关闭入口。
 *
 * 副作用：
 * - 会更新 Overlay 路由标记并触发导航返回。
 */
@ComponentV2
export struct SharedTestOverlayDestination {
  @Local private app: AppState = useAppState();
  @Local private panelOffsetY: number = 1200;
  @Local private panelTravelY: number = 1200;
  @Local private closing: boolean = false;
  @Local private entered: boolean = false;
  private dismissDoneTimerId: number = -1;
  private enterDuration: number = 280;
  private exitDuration: number = 250;

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
      this.app.nav.hasOverlayRoute = false;
      this.app.nav.back(false);
    }, this.exitDuration);
  }

  build() {
    NavDestination() {
      Column() {
        SharedInteractionTestPage({
          onRequestDismiss: () => {
            this.requestDismiss();
          },
        });
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .translate({ x: 0, y: this.panelOffsetY })
      .animation({
        duration: this.closing ? this.exitDuration : this.enterDuration,
        curve: Curve.EaseOut,
        playMode: PlayMode.Normal,
      })
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .backgroundColor(this.app.theme.palette.transparent)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .mode(NavDestinationMode.STANDARD)
    .onBackPressed(() => {
      this.requestDismiss();
      return true;
    });
  }
}
