import { AppState, useAppState } from '../../app/AppStates';

/**
 * 详情卡片基础组件。
 * 提供页面居中展示、背景遮罩和右上角关闭入口。
 */
@ComponentV2
export struct DetailCard {
  @Local private app: AppState = useAppState();
  @Param isVisible: boolean = false;
  @Event onClose: () => void = () => {};
  @BuilderParam content: () => void = this.defaultContent;
  @Local private maskOpacity: number = 0;
  @Local private cardScale: number = 0.96;

  aboutToAppear(): void {
    this.maskOpacity = 0;
    this.cardScale = 0.96;
    setTimeout(() => {
      this.maskOpacity = 1;
      this.cardScale = 1;
    }, 16);
  }

  private requestDismiss(): void {
    this.maskOpacity = 0;
    this.cardScale = 0.96;
    setTimeout(() => {
      this.onClose();
    }, 190);
  }

  @Builder
  private defaultContent() {
    Column({ space: 8 }) {
      Text('DetailCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('在此承载详情信息与编辑内容。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    if (this.isVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.app.theme.palette.mask)
          .opacity(this.maskOpacity)
          .animation({ duration: 220, curve: Curve.EaseOut, playMode: PlayMode.Normal })
          .onClick(() => {
            this.requestDismiss();
          });

        Column({ space: 10 }) {
          this.content();
        }
        .width('80%')
        .height('60%')
        .padding(18)
        .borderRadius(20)
        .backgroundColor(this.app.theme.palette.surface)
        .scale({ x: this.cardScale, y: this.cardScale })
        .animation({ duration: 220, curve: Curve.EaseOut, playMode: PlayMode.Normal })
        .shadow({ radius: 16, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 6 });
      }
      .width('100%')
      .height('100%')
      .zIndex(1100);
    }
  }
}
