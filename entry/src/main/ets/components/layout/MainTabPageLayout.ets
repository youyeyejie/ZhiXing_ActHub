import { AppState, useAppState } from "../../app/AppStates";
import { SafeAreaUtils } from "../../core/theme/SafeAreaUtils";

/**
 * 组件功能简介：
 * - 主标签页统一布局容器，封装标题栏、右上角动作入口与悬浮新建按钮。
 *
 * 可传入项：
 * - @Param title: 页面标题。
 * - @Param actionIcon/actionText: 右上角动作图标或文本（二选一显示）。
 * - @Param showFloatButton: 是否显示右下角悬浮新建按钮。
 * - @Event onActionTap: 点击右上角动作入口回调。
 * - @Event onClickFloatingButton: 点击悬浮按钮回调。
 * - @BuilderParam content: 页面主体内容。
 *
 * 返回行为：
 * - 返回全屏页面骨架并渲染头部与主体内容。
 *
 * 副作用：
 * - 点击头部动作与悬浮按钮会触发外部事件回调。
 */
@ComponentV2
export struct MainTabPageLayout {
  @Local private app: AppState = useAppState();
  @Param title: string = "";
  @Param actionIcon: Resource | undefined = undefined;
  @Param actionText: string = "";
  @Param showFloatButton: boolean = false;
  @Event onActionTap: () => void = () => {};
  @Event onClickFloatingButton: () => void = () => {};
  @BuilderParam content: () => void = this.emptyBuilder;

  @Builder
  private emptyBuilder() {}

@Builder
  private buildFloatingCreateButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Row() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([this.app.theme.palette.surface]);
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center);
    }
      .width(56)
      .height(56)
      .backgroundColor(this.app.theme.palette.primary)
      .onClick(() => {
        this.onClickFloatingButton();
      })
      .position({ right: "8%", bottom: "4%" })
      .zIndex(1);
  }

  private hasActionIcon(): boolean {
    return this.actionIcon !== undefined && this.actionIcon !== null;
  }

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)

        if (this.hasActionIcon() || this.actionText.length > 0) {
          Button() {
            if (this.hasActionIcon()) {
              SymbolGlyph(this.actionIcon)
                .fontSize(24)
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([this.app.theme.palette.textPrimary]);
            } else {
              Text(this.actionText)
                .fontSize(14)
                .fontColor(this.app.theme.palette.textSecondary);
            }
          }
            .type(ButtonType.Circle)
            .width(40)
            .height(40)
            .stateEffect(true)
            .backgroundColor(this.app.theme.palette.transparent)
            .onClick(this.onActionTap);
        }
      }
      .padding({
        top: SafeAreaUtils.getTopInset() + 20,
        right: 20,
        bottom: 20,
        left: 20,
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.app.theme.palette.background)
      .zIndex(1)

      if (this.showFloatButton) {
        this.buildFloatingCreateButton();
      }

      this.content()
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.app.theme.palette.background)
    .expandSafeArea([SafeAreaType.KEYBOARD]);
  }
}
