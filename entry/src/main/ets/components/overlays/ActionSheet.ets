import { AppState, useAppState } from '../../app/AppStates';

export class ActionSheetController {
  dismiss: () => void = () => {};
}

/**
 * 半屏弹出容器。
 * 统一遮罩、半屏高度和键盘避让偏移。
 */
@ComponentV2
export struct ActionSheet {
  @Local private app: AppState = useAppState();
  @Param isVisible: boolean = false;
  @Param panelHeight: string = '62%';
  @Param keyboardOffset: number = 0;
  @Param controller: ActionSheetController = new ActionSheetController();
  @Event onDismiss: () => void = () => {};

  @BuilderParam content: () => void = this.defaultContent;
  @Local private panelOffsetY: number = 600;
  @Local private maskOpacity: number = 0;

  @Builder
  private defaultContent() {
    Column({ space: 8 }) {
      Text('ActionSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('在此承载新建和详情编辑表单。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 12, bottom: 12 });
  }

  aboutToAppear(): void {
    this.controller.dismiss = () => {
      this.requestDismiss();
    };
    this.panelOffsetY = 600;
    this.maskOpacity = 0;
    setTimeout(() => {
      this.panelOffsetY = 0;
      this.maskOpacity = 1;
    }, 16);
  }

  private requestDismiss(): void {
    this.panelOffsetY = 600;
    this.maskOpacity = 0;

    setTimeout(() => {
      this.onDismiss();
    }, 190);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.isVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.app.theme.palette.mask)
          .opacity(this.maskOpacity)
          .onClick(() => {
            this.requestDismiss();
          });

        Column({ space: 12 }) {
          this.content();
        }
        .width('100%')
        .height(this.panelHeight)
        .padding({ left: 20, right: 20, top: 12, bottom: 20 + this.keyboardOffset })
        .borderRadius({ topLeft: 24, topRight: 24 })
        .backgroundColor(this.app.theme.palette.surface)
        .translate({ x: 0, y: this.panelOffsetY - this.keyboardOffset })
        .animation({ duration: 220, curve: Curve.EaseOut, playMode: PlayMode.Normal });
      }
    }
    .width('100%')
    .height('100%');
  }
}
