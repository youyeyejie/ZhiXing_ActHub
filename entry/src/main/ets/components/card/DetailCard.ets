import { AppState, useAppState } from '../../app/AppStates';

export class DetailCardController {
  dismiss: () => void = () => {};
}

/**
 * 详情卡片基础组件。
 * 使用页面内遮罩承载内容，统一遮罩点击、右上角关闭与系统返回关闭行为。
 */
@ComponentV2
export struct DetailCard {
  @Param controller: DetailCardController = new DetailCardController();
  @Event onDismiss: () => void = () => {};
  @BuilderParam content: () => void = this.defaultContent;
  @Local private app: AppState = useAppState();
  @Local private dismissing: boolean = false;
  @Local private maskOpacity: number = 0;
  @Local private cardScale: number = 0.88;
  @Local private cardOpacity: number = 0;

  aboutToAppear(): void {
    this.controller.dismiss = () => {
      this.requestDismiss();
    };
    this.dismissing = false;
    this.maskOpacity = 0;
    this.cardScale = 0.88;
    this.cardOpacity = 0;
    setTimeout(() => {
      this.maskOpacity = 1;
      this.cardScale = 1;
      this.cardOpacity = 1;
    }, 16);
  }

  private requestDismiss(): void {
    if (this.dismissing) {
      return;
    }
    this.dismissing = true;
    this.maskOpacity = 0;
    this.cardScale = 0.88;
    this.cardOpacity = 0;
    setTimeout(() => {
      this.onDismiss();
    }, 200);
  }

  @Builder
  private buildHeader() {
    Row() {
      Blank();

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('×')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textSecondary);
      }
        .width(28)
        .height(28)
      .backgroundColor(this.app.theme.palette.surface)
      .onClick(() => {
        this.requestDismiss();
      });
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center);
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
    Stack({ alignContent: Alignment.Center }) {
			Column()
				.width('100%')
				.height('100%')
				.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
				.backgroundColor(this.app.theme.palette.mask)
				.opacity(this.maskOpacity)
				.animation({ duration: 200, curve: Curve.EaseOut, playMode: PlayMode.Normal })
				.onClick(() => {
					this.requestDismiss();
				});

			Column({ space: 10 }) {
				this.buildHeader();

				Column({ space: 10 }) {
					this.content();
				}
				.width('100%')
				.layoutWeight(1)
				.alignItems(HorizontalAlign.Start);
			}
			.width('80%')
			.height('60%')
			.padding(18)
			.borderRadius(20)
			.backgroundColor(this.app.theme.palette.surface)
			.shadow({ radius: 16, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 6 })
			.opacity(this.cardOpacity)
			.scale({ x: this.cardScale, y: this.cardScale })
			.animation({ duration: 200, curve: Curve.EaseOut, playMode: PlayMode.Normal });
		}
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
