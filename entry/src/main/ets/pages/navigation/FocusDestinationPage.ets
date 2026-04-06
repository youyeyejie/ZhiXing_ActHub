import { FocusPage } from '../focus';
import { AppState, useAppState } from '../../app/AppStates';
import { NavDialogOverlay, NavDialogOverlayController } from '../../components/overlays/NavDialogOverlay';

/**
 * 专注页路由容器。
 * 通过通用 nav overlay 容器承载专注模块，并复用统一的入场/退出动画。
 */
@ComponentV2
export struct FocusDestinationPage {
  @Local private app: AppState = useAppState();
  private overlayController: NavDialogOverlayController = new NavDialogOverlayController();

  @Builder
  private buildFocusPanel() {
    Column() {
      Column({ space: 8 }) {
        Row() {
          Button('返回')
            .type(ButtonType.Normal)
            .onClick(() => {
              this.overlayController.dismiss();
            });
        }
        .width('100%')

        Text('进入专注')
          .fontSize(13)
          .fontColor(this.app.theme.palette.textTertiary);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 8 });

      FocusPage();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .borderRadius({ topLeft: 28, topRight: 28, bottomLeft: 0, bottomRight: 0 })
    .clip(true);
  }

  build() {
    NavDialogOverlay({
      controller: this.overlayController,
      onDismiss: () => {
        this.app.nav.back(false);
      }
    }) {
      Column() {
        Blank()
          .layoutWeight(1);

        this.buildFocusPanel();
      }
      .width('100%')
      .height('100%');
    }
  }
}

@Builder
export function FocusDestinationPageBuilder(_name: string, _param: Object) {
  FocusDestinationPage();
}
