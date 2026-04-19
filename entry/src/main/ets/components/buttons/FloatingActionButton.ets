import { AppState, useAppState } from "../../app/AppStates";

/**
 * 组件功能简介：
 * - 通用悬浮操作按钮组件，用于页面右下角新增入口与快捷操作触发。
 *
 * 可传入项：
 * - `content`：图标资源。
 * - `label`：按钮文本。
 * - `buttonSize`、`iconSize`：尺寸配置。
 * - `onTap`：点击回调。
 *
 * 返回行为：
 * - 渲染圆形悬浮按钮，并在点击时触发回调。
 *
 * 副作用：
 * - 会触发 `onTap` 事件。
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
