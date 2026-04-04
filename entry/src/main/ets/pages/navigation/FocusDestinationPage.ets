import display from '@ohos.display';
import { FocusPage } from '../focus';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 专注页路由容器。
 * 当前先作为全屏目的页承载专注模块，后续再补沉浸式控制栏和状态同步。
 */
@ComponentV2
export struct FocusDestinationPage {
  @Local private app: AppState = useAppState();
  @Local private pathStack: NavPathStack | undefined = undefined;
  @Local private pageOffsetY: number = 1200;
  @Local private closing: boolean = false;
  @Local private entered: boolean = false;

  aboutToAppear(): void {
    this.pageOffsetY = this.resolveOffscreenOffset();
    this.entered = false;
  }

  private resolveOffscreenOffset(): number {
    try {
      const info = display.getDefaultDisplaySync();
      return Math.max(info.width, info.height);
    } catch (_error) {
      return 1200;
    }
  }

  private closeWithAnimation(): void {
    if (this.closing) {
      return;
    }
    this.closing = true;
    this.pageOffsetY = this.resolveOffscreenOffset();
    setTimeout(() => {
      this.app.nav.back();
      this.closing = false;
    }, 500);
  }

  private startEnterAnimation(): void {
    if (this.entered) {
      return;
    }
    this.entered = true;
    setTimeout(() => {
      this.pageOffsetY = 0;
    }, 16);
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Row() {
          Button('返回')
            .type(ButtonType.Normal)
            .onClick(() => {
              this.closeWithAnimation();
            });

          Blank();
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 20, right: 20, top: 16 });

        FocusPage();
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background)
      .translate({ x: 0, y: this.pageOffsetY })
      .animation({ duration: 500, curve: Curve.EaseInOut, playMode: PlayMode.Normal });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.startEnterAnimation();
    })
    .onBackPressed(() => {
      this.closeWithAnimation();
      return true;
    });
  }
}

@Builder
export function FocusDestinationPageBuilder(_name: string, _param: Object) {
  FocusDestinationPage();
}
