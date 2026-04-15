import { AppState, useAppState } from "../../../app/AppStates";
import { AIService, useAIService } from "../../../core/services/AIService";
import { IdeaPageState, useIdeaPageState } from "../IdeaPageState";
import { Idea } from "../../../core/models/Idea";
import { AppOverlayRoute } from "../../../app/AppConstants";
import promptAction from "@ohos.promptAction";

/**
 * AI 洞察页面。
 * 基于用户闪记内容生成深度洞察报告，作为独立页面展示。
 */
@ComponentV2
export struct AIInsightPage {
  @Local private app: AppState = useAppState();
  @Local private state: IdeaPageState = useIdeaPageState();
  @Local private aiService: AIService = useAIService();
  @Param onRequestDismiss: () => void = () => {};

  @Local private report: string = "";
  @Local private loading: boolean = true;
  @Local private errorMessage: string = "";

  // 获取顶部安全区域高度（固定值避免兼容性问题）
  private getSafeAreaTop(): number {
    return 44;
  }

  aboutToAppear(): void {
    // 延迟执行，确保页面先渲染出来
    setTimeout(() => {
      this.generateReport();
    }, 100);
  }

  /**
   * 准备发送给 AI 的闪记内容。
   */
  private prepareIdeasContent(): string {
    if (this.state.ideas.length === 0) {
      return "";
    }

    // 取最近 20 条闪记
    const recentIdeas = this.state.ideas.slice(0, 20);
    const lines: string[] = [];

    recentIdeas.forEach((idea: Idea, index: number) => {
      const title = idea.title.length > 0 ? `【${idea.title}】` : "";
      const content = idea.content.length > 200 ? idea.content.substring(0, 200) + "..." : idea.content;
      lines.push(`${index + 1}. ${title}${content}`);
    });

    return lines.join("\n\n");
  }

  /**
   * 生成洞察报告。
   */
  private async generateReport(): Promise<void> {
    if (this.state.ideas.length === 0) {
      this.errorMessage = "暂无闪记内容可分析";
      this.loading = false;
      return;
    }

    this.loading = true;
    this.report = "";
    this.errorMessage = "";

    try {
      const content = this.prepareIdeasContent();
      const result = await this.aiService.generateInsight(content);
      // 检查返回结果是否是错误信息
      if (result.startsWith("请求失败") || result.startsWith("请求出错") || result.startsWith("请先配置") || result.startsWith("API 错误") || result.startsWith("网络错误")) {
        this.errorMessage = result;
      } else {
        this.report = result;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.errorMessage = `生成失败：${errorMsg}`;
    } finally {
      this.loading = false;
    }
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1200 });
    } catch (_error) {}
  }

  build() {
    Column({ space: 0 }) {
      // 顶部安全区域占位
      Row().width('100%').height(this.getSafeAreaTop())

      // 顶部导航栏
      Row() {
        Button() {
          SymbolGlyph($r("sys.symbol.chevron_left"))
            .fontSize(20)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([this.app.theme.palette.textPrimary]);
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.onRequestDismiss();
        })

        Text("AI 洞察")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.textPrimary)

        Blank()

        // 重新生成按钮
        Button() {
          SymbolGlyph($r("sys.symbol.arrow_clockwise"))
            .fontSize(18)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([this.loading ? this.app.theme.palette.textTertiary : this.app.theme.palette.primary]);
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .enabled(!this.loading)
        .onClick(() => {
          this.generateReport();
        })
      }
      .width("100%")
      .height(56)
      .padding({ left: 8, right: 8 })

      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color(this.app.theme.palette.border)

      // 内容区域
      if (this.loading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(this.app.theme.palette.primary)
          Text("正在分析你的闪记...")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary)
          Text("AI 正在深度解读你的思考模式")
            .fontSize(12)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        // 错误状态
        Column({ space: 16 }) {
          SymbolGlyph($r("sys.symbol.exclamationmark_triangle"))
            .fontSize(48)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor(["#F59E0B"]);

          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary)
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })

          Button("重新尝试")
            .fontSize(14)
            .fontColor("#FFFFFF")
            .backgroundColor(this.app.theme.palette.primary)
            .borderRadius(999)
            .height(40)
            .padding({ left: 24, right: 24 })
            .onClick(() => {
              this.generateReport();
            })
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.report.length > 0) {
        // 报告内容
        Scroll() {
          Column({ space: 16 }) {
            // 报告标题
            Row({ space: 8 }) {
              SymbolGlyph($r("sys.symbol.wand_and_stars"))
                .fontSize(20)
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([this.app.theme.palette.primary]);

              Text("你的闪记洞察")
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.app.theme.palette.textPrimary);
            }
            .width("100%")
            .justifyContent(FlexAlign.Start)

            // 统计信息
            Row({ space: 16 }) {
              Column({ space: 4 }) {
                Text(`${this.state.ideas.length}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.app.theme.palette.primary)
                Text("闪记总数")
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textTertiary)
              }

              Divider()
                .vertical(true)
                .height(32)
                .strokeWidth(0.5)
                .color(this.app.theme.palette.border)

              Column({ space: 4 }) {
                Text(`${this.state.ideas.reduce((sum, idea) => sum + (idea.length || 0), 0)}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.app.theme.palette.primary)
                Text("总字数")
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textTertiary)
              }
            }
            .width("100%")
            .padding(16)
            .borderRadius(12)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)

            // 报告正文
            Text(this.report)
              .fontSize(15)
              .fontColor(this.app.theme.palette.textPrimary)
              .lineHeight(26)
              .width("100%")

            // 底部留白
            Column().height(32)
          }
          .width("100%")
          .padding(20)
          .alignItems(HorizontalAlign.Start)
        }
        .width("100%")
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      } else {
        // 空状态
        Column({ space: 12 }) {
          Text("暂无报告内容")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.app.theme.palette.background)
  }
}

/**
 * AI 洞察入口按钮。
 * 显示在热力图旁边，点击后跳转到洞察页面。
 */
@ComponentV2
export struct AIInsightPanel {
  @Local private app: AppState = useAppState();
  @Local private state: IdeaPageState = useIdeaPageState();

  private openInsightPage(): void {
    this.app.nav.pushOverlayByName(AppOverlayRoute.AI_INSIGHT, undefined);
  }

  build() {
    Column({ space: 8 }) {
      // AI 洞察按钮 - 更明显的样式
      Button() {
        Column({ space: 4 }) {
          SymbolGlyph($r("sys.symbol.wand_and_stars"))
            .fontSize(24)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor(["#FFFFFF"]);

          Text("AI 洞察")
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor("#FFFFFF")
        }
        .padding(8)
      }
      .type(ButtonType.Circle)
      .width(64)
      .height(64)
      .backgroundColor(this.app.theme.palette.primary)
      .shadow({
        radius: 8,
        color: "rgba(76, 175, 122, 0.4)",
        offsetY: 4
      })
      .onClick(() => {
        this.openInsightPage();
      })

      // 笔记数量提示
      Text(`${this.state.ideas.length} 条笔记`)
        .fontSize(10)
        .fontColor(this.app.theme.palette.textTertiary)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
