import { AppState, useAppState } from "../../app/AppStates";

/**
 * 通用右下角悬浮新增按钮。
 * 统一用于主页面的新建入口，避免各页重复维护样式和定位。
 */
@ComponentV2
export struct FloatingActionButton {
  @Local private app: AppState = useAppState();
  @Param content: Resource = $r("sys.symbol.plus");
  @Param label: string = "";
  @Param buttonSize: number = 56;
  @Param iconSize: number = 28;
  @Event onTap: () => void = () => {};

  build() {
    Button() {
      if (this.label.trim().length > 0) {
        Text(this.label)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.surface);
      } else {
        SymbolGlyph(this.content)
          .fontSize(this.iconSize)
          .fontColor([this.app.theme.palette.surface]);
      }
    }
    .type(ButtonType.Circle)
    .width(this.buttonSize)
    .height(this.buttonSize)
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
