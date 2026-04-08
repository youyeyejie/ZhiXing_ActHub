import { AppState, useAppState } from "../../app/AppStates";
import { PageScrollLayout } from "./PageScrollLayout";
import { SafeAreaUtils } from "../../core/theme/SafeAreaUtils";

/**
 * 主标签页统一布局容器。
 * 统一处理整页背景、顶部标题栏和顶部起排的滚动内容。
 */
@ComponentV2
export struct MainTabPageLayout {
  @Local private app: AppState = useAppState();
  @Param title: string = "";
  @Param actionIcon: ResourceStr = "";
  @Param actionText: string = "";
  @Event onActionTap: () => void = () => {};
  @BuilderParam content: () => void = this.emptyBuilder;

  @Builder
  private emptyBuilder() {}

  private hasActionIcon(): boolean {
    return typeof this.actionIcon === 'string' ? this.actionIcon.length > 0 : true;
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
              Image(this.actionIcon)
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain);
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
            .backgroundColor(Color.Transparent)
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

      PageScrollLayout() {
        this.content()
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.app.theme.palette.background)
    .expandSafeArea([SafeAreaType.KEYBOARD]);
  }
}
