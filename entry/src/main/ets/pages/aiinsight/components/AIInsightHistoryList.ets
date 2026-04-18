import { AppState, useAppState } from '../../../app/AppStates';
import { AIInsightState, InsightRecord, useAIInsightState } from '../AIInsightState';

/**
 * AI 洞察历史列表。
 * 展示过往洞察记录卡片，或空状态呼吸感动画。
 */
@ComponentV2
export struct AIInsightHistoryList {
  @Local private app: AppState = useAppState();
  @Local private state: AIInsightState = useAIInsightState();
  @Local private breathScale: number = 1.0;
  private breathTimerId: number = -1;

  aboutToAppear(): void {
    this.breathTimerId = setInterval(() => {
      this.breathScale = this.breathScale > 1.0 ? 0.95 : 1.05;
    }, 1800);
  }

  aboutToDisappear(): void {
    if (this.breathTimerId >= 0) {
      clearInterval(this.breathTimerId);
      this.breathTimerId = -1;
    }
  }

  /**
   * 格式化时间为"今天 HH:MM"、"昨天 HH:MM"或"MM-DD HH:MM"。
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const timeStr = `${hours}:${minutes}`;

    if (
      date.getFullYear() === now.getFullYear() &&
      date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate()
    ) {
      return `今天 ${timeStr}`;
    }

    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    if (
      date.getFullYear() === yesterday.getFullYear() &&
      date.getMonth() === yesterday.getMonth() &&
      date.getDate() === yesterday.getDate()
    ) {
      return `昨天 ${timeStr}`;
    }

    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${month}-${day} ${timeStr}`;
  }

  build() {
    Column({ space: 12 }) {
      if (this.state.records.length === 0) {
        // 空状态
        Column({ space: 16 }) {
          SymbolGlyph($r('sys.symbol.lightbulb'))
            .fontSize(56)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([this.app.theme.palette.textTertiary])
            .scale({ x: this.breathScale, y: this.breathScale })
            .opacity(this.breathScale > 1.0 ? 1.0 : 0.5)
            .animation({ duration: 1800, curve: Curve.EaseInOut })

          Text('这里空空如也')
            .fontSize(16)
            .fontColor(this.app.theme.palette.textSecondary)

          Text('点按上方按钮开启第一次深度洞察')
            .fontSize(13)
            .fontColor(this.app.theme.palette.textTertiary)
        }
        .width('100%')
        .padding({ top: 48, bottom: 48 })
        .alignItems(HorizontalAlign.Center)
      } else {
        // 历史标题
        Text('洞察历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textSecondary)
          .width('100%')

        // 历史记录列表
        ForEach(
          this.state.records,
          (record: InsightRecord) => {
            Column({ space: 8 }) {
              // 顶部：模式标签 + 时间
              Row() {
                Text(record.mode === 'global' ? '全局分析' : '精准分析')
                  .fontSize(11)
                  .fontColor(this.app.theme.palette.textPrimary)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(10)
                  .backgroundColor(record.mode === 'global' ? this.app.theme.palette.primary : this.app.theme.palette.info)

                Blank()

                Text(this.formatTime(record.createdAt))
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textTertiary)
              }
              .width('100%')

              // 关键词标签
              if (record.keywords.length > 0) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(
                    record.keywords,
                    (keyword: string, kwIdx: number) => {
                      Text(keyword)
                        .fontSize(12)
                        .fontColor(this.app.theme.palette.textSecondary)
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(8)
                        .backgroundColor(this.app.theme.palette.surfaceSecondary)
                        .margin({ right: 6, bottom: 4 })
                    },
                    (keyword: string, kwIdx: number) => `kw_${record.id}_${kwIdx}`,
                  )
                }
                .width('100%')
              }

              // 摘要
              if (record.summary.length > 0) {
                Text(record.summary)
                  .fontSize(13)
                  .fontColor(this.app.theme.palette.textSecondary)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .lineHeight(20)
              }
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface)
            .onClick(() => {
              this.state.openRecord(record);
            })
          },
          (record: InsightRecord) => `insight_record_${record.id}`,
        )
      }
    }
    .width('100%')
  }
}
