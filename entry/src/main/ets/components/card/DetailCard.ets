import { AppState, useAppState } from '../../app/AppStates';

/**
 * 类功能简介：
 * - DetailCard 外部控制器，提供主动关闭能力。
 *
 * 可传入项：
 * - 无（直接调用实例方法字段 `dismiss`）。
 *
 * 返回行为：
 * - 调用 `dismiss` 时执行组件内部注册的关闭流程。
 *
 * 副作用：
 * - 触发 DetailCard 关闭动画与 onDismiss 回调。
 */
export class DetailCardController {
  dismiss: () => void = () => {};
}

/**
 * 组件功能简介：
 * - 详情卡片容器组件，统一遮罩、缩放动画和关闭入口。
 *
 * 可传入项：
 * - @Param controller: 外部控制器，用于主动关闭。
 * - @Param cardHeight: 卡片高度，默认 60%。
 * - @Event onDismiss: 卡片关闭完成后的回调。
 * - @BuilderParam content: 详情主体内容。
 *
 * 返回行为：
 * - 返回全屏遮罩与居中详情卡片。
 *
 * 副作用：
 * - 组件出现时注册控制器关闭函数并启动入场动画。
 * - 关闭时触发延时 onDismiss 回调。
 */
@ComponentV2
export struct DetailCard {
  @Param controller: DetailCardController = new DetailCardController();
  @Param title: string = '详情';
  @Param cardHeight: string = '60%';
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
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1);

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('×')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textSecondary);
      }
        .width(28)
        .height(28)
      .backgroundColor(this.app.theme.palette.surface)
      .margin({ left: 8 })
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
        .justifyContent(FlexAlign.Start)
				.alignItems(HorizontalAlign.Start);
			}
			.width('80%')
      .height(this.cardHeight)
      .justifyContent(FlexAlign.Start)
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
