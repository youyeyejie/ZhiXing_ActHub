import { AppState, useAppState } from "../../../app/AppStates";
import { AppOverlayRoute } from "../../../app/AppConstants";

/**
 * AI 洞察入口按钮。
 * 点击后通过 overlay 路由打开 AI 洞察中心页面。
 */
@ComponentV2
export struct AIInsightPanel {
  @Local private app: AppState = useAppState();

  private openInsightPage(): void {
    this.app.nav.pushOverlayByName(AppOverlayRoute.AI_INSIGHT, undefined);
  }

  build() {
    Button() {
      SymbolGlyph($r("sys.symbol.wand_and_stars"))
        .fontSize(24)
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        .fontColor(["#FFFFFF"]);
    }
    .type(ButtonType.Circle)
    .width(56)
    .height(56)
    .backgroundColor(this.app.theme.palette.primary)
    .shadow({
      radius: 8,
      color: "rgba(76, 175, 122, 0.4)",
      offsetY: 4,
    })
    .onClick(() => {
      this.openInsightPage();
    })
  }
}
