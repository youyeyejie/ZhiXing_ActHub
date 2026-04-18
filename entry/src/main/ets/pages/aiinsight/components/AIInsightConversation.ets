import { AppState, useAppState } from '../../../app/AppStates';
import { AIInsightState, useAIInsightState } from '../AIInsightState';
import { MarkdownRenderer } from './MarkdownRenderer';

/**
 * AI 洞察对话流界面。
 * 展示洞察流式生成过程（自动滚动）和完成后的报告。
 */
@ComponentV2
export struct AIInsightConversation {
  @Local private app: AppState = useAppState();
  @Local private state: AIInsightState = useAIInsightState();
  @Local private dotPhase: number = 0;
  private dotTimerId: number = -1;
  private scrollTimerId: number = -1;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 跳动点动画定时器
    this.dotTimerId = setInterval(() => {
      this.dotPhase = (this.dotPhase + 1) % 3;
    }, 600);

    // 自动滚动定时器：流式输出时持续滚到底
    this.scrollTimerId = setInterval(() => {
      if (this.state.isGenerating && this.state.generatingText.length > 0) {
        this.scroller.scrollEdge(Edge.Bottom);
      }
    }, 100);
  }

  aboutToDisappear(): void {
    if (this.dotTimerId >= 0) {
      clearInterval(this.dotTimerId);
      this.dotTimerId = -1;
    }
    if (this.scrollTimerId >= 0) {
      clearInterval(this.scrollTimerId);
      this.scrollTimerId = -1;
    }
  }

  build() {
    Column({ space: 0 }) {
      // 统计信息卡片
      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text(`${this.state.activeNoteCount}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.primary)
          Text('参与笔记')
            .fontSize(11)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width("40%")
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(28)
          .strokeWidth(0.5)
          .color(this.app.theme.palette.border)

        Column({ space: 4 }) {
          Text(`${this.state.activeTotalLength}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.primary)
          Text('总字数')
            .fontSize(11)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width("40%")
        .alignItems(HorizontalAlign.Center)
      }
      .width('90%')
      .padding(16)
      .margin({ left: 20, right: 20, top: 12, bottom: 8 })
      .borderRadius(16)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)
      .justifyContent(FlexAlign.Center)

      // 内容滚动区
      Scroll(this.scroller) {
        Column({ space: 0 }) {
          // 思考中状态
          if (this.state.isGenerating && this.state.generatingText.length === 0 && this.state.errorMessage.length === 0) {
            Column({ space: 12 }) {
              Row({ space: 6 }) {
                Text('AI 正在思考中')
                  .fontSize(14)
                  .fontColor(this.app.theme.palette.textSecondary)
                this.buildThinkingDots()
              }
            }
            .width('100%')
            .padding({ top: 40, bottom: 40 })
            .alignItems(HorizontalAlign.Center)
          }

          // 错误状态
          if (this.state.errorMessage.length > 0) {
            Column({ space: 16 }) {
              SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
                .fontSize(40)
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([this.app.theme.palette.warning]);

              Text(this.state.errorMessage)
                .fontSize(14)
                .fontColor(this.app.theme.palette.textSecondary)
                .textAlign(TextAlign.Center)
                .padding({ left: 20, right: 20 })

              Button('重新尝试')
                .fontSize(14)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .borderRadius(999)
                .height(40)
                .padding({ left: 24, right: 24 })
                .onClick(() => {
                  this.state.startGlobalInsight();
                })
            }
            .width('100%')
            .padding({ top: 40, bottom: 40 })
            .alignItems(HorizontalAlign.Center)
          }

          // Markdown 内容
          if (this.state.generatingText.length > 0) {
            Column() {
              MarkdownRenderer({ text: this.state.generatingText })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 8 })
          }

          // 底部留白
          Column().height(100)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 底部操作栏
      this.buildBottomBar()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildThinkingDots() {
    Row({ space: 4 }) {
      Text('\u25CF')
        .fontSize(8)
        .fontColor(this.dotPhase === 0 ? this.app.theme.palette.primary : this.app.theme.palette.textTertiary)
        .scale({ x: this.dotPhase === 0 ? 1.4 : 1.0, y: this.dotPhase === 0 ? 1.4 : 1.0 })
        .animation({ duration: 300, curve: Curve.EaseInOut })
      Text('\u25CF')
        .fontSize(8)
        .fontColor(this.dotPhase === 1 ? this.app.theme.palette.primary : this.app.theme.palette.textTertiary)
        .scale({ x: this.dotPhase === 1 ? 1.4 : 1.0, y: this.dotPhase === 1 ? 1.4 : 1.0 })
        .animation({ duration: 300, curve: Curve.EaseInOut })
      Text('\u25CF')
        .fontSize(8)
        .fontColor(this.dotPhase === 2 ? this.app.theme.palette.primary : this.app.theme.palette.textTertiary)
        .scale({ x: this.dotPhase === 2 ? 1.4 : 1.0, y: this.dotPhase === 2 ? 1.4 : 1.0 })
        .animation({ duration: 300, curve: Curve.EaseInOut })
    }
  }

  @Builder
  private buildBottomBar() {
    Row() {
      if (this.state.isGenerating) {
        // 停止生成按钮
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(16)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
              .fontColor([this.app.theme.palette.surface]);
            Text('停止生成')
              .fontSize(14)
              .fontColor(this.app.theme.palette.surface)
          }
        }
        .height(44)
        .padding({ left: 20, right: 20 })
        .borderRadius(999)
        .backgroundColor(this.app.theme.palette.primary)
        .onClick(() => {
          this.state.stopGeneration();
        })
      } else if (this.state.generatingText.length > 0) {
        // 复制按钮
        Button('复制报告')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
        .height(44)
        .padding({ left: 20, right: 20 })
        .borderRadius(999)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .onClick(() => {
          this.state.copyReport(this.state.generatingText);
        })
      }
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.app.theme.palette.background)
  }
}
