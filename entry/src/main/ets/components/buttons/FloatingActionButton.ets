import { AppState, useAppState } from "../../app/AppStates";

/**
 * 通用右下角悬浮新增按钮。
 * 统一用于主页面的新建入口，避免各页重复维护样式和定位。
 */
@ComponentV2
export struct FloatingActionButton {
  @Local private app: AppState = useAppState();
  @Param content: Resource = $r("sys.media.ohos_ic_public_add");
  @Event onTap: () => void = () => {};

  build() {
    Button() {
      Image(this.content)
        .width(28)
        .height(28)
        .fillColor("#FFFFFF")
    }
    .type(ButtonType.Circle)
    .width(56)
    .height(56)
    .backgroundColor(this.app.theme.palette.primary)
    .shadow({
      radius: 16,
      color: this.app.theme.palette.primary + "40",
      offsetX: 0,
      offsetY: 4,
    })
    .margin({ right: 20, bottom: "6%" })
    .onClick(() => {
      this.onTap();
    });
  }
}
