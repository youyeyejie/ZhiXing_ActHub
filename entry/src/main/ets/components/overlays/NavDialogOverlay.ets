import display from "@ohos.display";

export class NavDialogOverlayController {
  dismiss: () => void = () => {};
}

/**
 * 基于 NavDestination(DIALOG) 的通用覆盖层容器。
 * 用于承接通过 nav stack push 的遮罩式页面，并提供自底向上的进入/退出动画。
 */
@ComponentV2
export struct NavDialogOverlay {
  @Param controller: NavDialogOverlayController = new NavDialogOverlayController();
  @Event onDismiss: () => void = () => {};
  @Param enterDuration: number = 600;
  @Param exitDuration: number = 600;
  @BuilderParam content: () => void = this.emptyContent;

  @Local private panelOffsetY: number = 1200;
  @Local private panelTravelY: number = 1200;
  @Local private closing: boolean = false;
  @Local private entered: boolean = false;

  @Builder
  private emptyContent() {}

  aboutToAppear(): void {
    this.panelTravelY = this.resolveOffscreenOffset();
    this.panelOffsetY = this.panelTravelY;
    this.closing = false;
    this.entered = false;
    this.controller.dismiss = () => {
      this.requestDismiss();
    };
    setTimeout(() => {
      this.startEnterAnimation();
    }, 16);
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
    this.closing = true;
    this.panelOffsetY = this.panelTravelY;
    setTimeout(() => {
      this.onDismiss();
      this.closing = false;
    }, this.exitDuration);
  }

  build() {
    NavDestination() {
      Column() {
        this.content()
      }
      .width("100%")
      .height("100%")
      .translate({ x: 0, y: this.panelOffsetY })
      .animation({
        duration: this.closing ? this.exitDuration : this.enterDuration,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal,
      })
    }
    .width("100%")
    .height("100%")
    .backgroundColor(Color.Transparent)
    .mode(NavDestinationMode.DIALOG)
    .onBackPressed(() => {
      this.requestDismiss();
      return true;
    });
  }
}
