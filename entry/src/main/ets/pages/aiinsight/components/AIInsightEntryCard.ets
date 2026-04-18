import { AppState, useAppState } from '../../../app/AppStates';

/**
 * AI 洞察功能入口卡片。
 * 玻璃拟态风格，左侧图标 + 右侧标题描述。
 */
@ComponentV2
export struct AIInsightEntryCard {
  @Local private app: AppState = useAppState();
  @Param icon: Resource = $r('sys.symbol.lightbulb');
  @Param title: string = '';
  @Param description: string = '';
  @Param disabled: boolean = false;
  @Event onTap: () => void = () => {};

  build() {
    Row({ space: 16 }) {
      // 左侧圆形图标区
      Column() {
        SymbolGlyph(this.icon)
          .fontSize(24)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([this.app.theme.palette.surface]);
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.app.theme.palette.primary)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 右侧标题描述
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.description)
          .fontSize(13)
          .fontColor(this.app.theme.palette.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧箭头
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        .fontColor([this.app.theme.palette.textTertiary]);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface)
    .backdropBlur(20)
    .border({
      width: 0.5,
      color: this.app.theme.palette.border,
    })
    .opacity(this.disabled ? 0.5 : 1.0)
    .onClick(() => {
      if (!this.disabled) {
        this.onTap();
      }
    });
  }
}
