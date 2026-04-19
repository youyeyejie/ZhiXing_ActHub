import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - ActionSheet 外部控制器，提供主动关闭能力。
 *
 * 可传入项：
 * - 无（直接调用实例方法字段 `dismiss`）。
 *
 * 返回行为：
 * - 调用 `dismiss` 时执行组件内部注册的关闭流程。
 *
 * 副作用：
 * - 触发 ActionSheet 关闭动画与 onDismiss 回调。
 */
export class ActionSheetController {
  dismiss: () => void = () => {};
}

/**
 * 组件功能简介：
 * - 半屏弹出容器，统一遮罩、面板动画与键盘偏移处理。
 *
 * 可传入项：
 * - @Param panelHeight: 弹层高度，默认 50%。
 * - @Param keyboardOffset: 键盘抬升偏移。
 * - @Param controller: 外部控制器，可主动触发 dismiss。
 * - @Event onDismiss: 弹层真正关闭后的回调。
 * - @BuilderParam content: 弹层主体内容。
 *
 * 返回行为：
 * - 返回全屏遮罩 + 底部面板的弹层结构。
 *
 * 副作用：
 * - 组件出现时会注册控制器关闭函数并启动入场动画。
 * - 关闭时会触发延时回调执行 onDismiss。
 */
@ComponentV2
export struct ActionSheet {
  @Local private app: AppState = useAppState();
  @Param panelHeight: string = '50%';
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
			Column()
				.width('100%')
				.height('100%')
				.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
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
			.borderRadius(20)
			.backgroundColor(this.app.theme.palette.surface)
			.translate({ x: 0, y: this.panelOffsetY - this.keyboardOffset })
			.animation({ duration: 220, curve: Curve.EaseOut, playMode: PlayMode.Normal });
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
