import { AppState, useAppState } from '../../../app/AppStates';
import { AIInsightState, useAIInsightState } from '../AIInsightState';
import { IdeaPageState, useIdeaPageState } from '../IdeaPageState';
import { Idea } from '../../../core/models/Idea';

/**
 * 精准洞察笔记选择弹层内容。
 * 嵌入 ActionSheet 展示，提供笔记列表 + Checkbox 勾选。
 */
@ComponentV2
export struct AIInsightNoteSelector {
  @Local private app: AppState = useAppState();
  @Local private state: AIInsightState = useAIInsightState();
  @Local private ideaState: IdeaPageState = useIdeaPageState();

  /**
   * 关闭弹层并启动精准洞察分析。
   */
  private startAnalysis(): void {
    this.app.nav.back(false);
    setTimeout(() => {
      this.state.startSelectedInsight();
    }, 200);
  }

  /**
   * 格式化时间。
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${month}-${day}`;
  }

  build() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Text('选择要分析的笔记')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.textPrimary)
        Blank()
        if (this.state.selectedNoteIds.length > 0) {
          Text(`已选 ${this.state.selectedNoteIds.length} 篇`)
            .fontSize(13)
            .fontColor('#004027')
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 12 })

      // 笔记列表
      List({ space: 0 }) {
        ForEach(
          this.ideaState.ideas,
          (idea: Idea) => {
            ListItem() {
              Row({ space: 12 }) {
                // Checkbox
                Checkbox()
                  .select(this.state.isNoteSelected(idea.id))
                  .selectedColor('#004027')
                  .width(20)
                  .height(20)
                  .onChange((checked: boolean) => {
                    this.state.toggleNoteSelection(idea.id);
                  })

                // 笔记信息
                Column({ space: 4 }) {
                  Text(idea.title.length > 0 ? idea.title : '无标题')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.app.theme.palette.textPrimary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(idea.content)
                    .fontSize(13)
                    .fontColor(this.app.theme.palette.textSecondary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.formatTime(idea.timestamp))
                    .fontSize(11)
                    .fontColor(this.app.theme.palette.textTertiary)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
              .onClick(() => {
                this.state.toggleNoteSelection(idea.id);
              })
            }
          },
          (idea: Idea) => `selector_${idea.id}`,
        )
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .divider({
        strokeWidth: 0.5,
        color: this.app.theme.palette.border,
        startMargin: 52,
        endMargin: 20,
      })

      // 底部操作区
      if (this.state.selectedNoteIds.length > 0) {
        Column() {
          Button(`开始分析 (${this.state.selectedNoteIds.length} 篇)`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(48)
            .borderRadius(24)
            .backgroundColor('#004027')
            .onClick(() => {
              this.startAnalysis();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
        .backgroundColor(this.app.theme.palette.background)
      }
    }
    .width('100%')
    .height('100%')
  }
}
