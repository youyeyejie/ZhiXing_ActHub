import { AppState, useAppState } from '../../../app/AppStates';
import { AIInsightState, useAIInsightState } from '../AIInsightState';
import { IdeaPageState, useIdeaPageState } from '../../idea/IdeaPageState';
import { Idea } from '../../../core/models/Idea';
import { FormTypography } from '../../../core/theme/FormTypography';

/**
 * 精准洞察笔记选择弹层内容。
 * 嵌入 ActionSheet 展示，提供笔记列表 + Checkbox 勾选。
 */
@ComponentV2
export struct AIInsightNoteSelector {
  @Local private app: AppState = useAppState();
  @Local private state: AIInsightState = useAIInsightState();
  @Local private ideaState: IdeaPageState = useIdeaPageState();

  private get canStartAnalysis(): boolean {
    return this.state.selectedNoteIds.length > 0;
  }

  /**
   * 关闭弹层并启动精准洞察分析。
   */
  private startAnalysis(): void {
    if (!this.canStartAnalysis) {
      return;
    }

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

  private setNoteSelection(ideaId: number, checked: boolean): void {
    if (checked) {
      this.state.selectNote(ideaId);
      return;
    }
    this.state.deselectNote(ideaId);
  }

  @Builder
  private buildStartButton(): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.play_fill'))
        .fontSize(18)
        .fontColor([this.app.theme.palette.surface]);
    }
    .width(34)
    .height(34)
    .backgroundColor(this.app.theme.palette.primary)
    .fontColor(this.app.theme.palette.surface)
    .enabled(this.canStartAnalysis)
    .onClick(() => {
      this.startAnalysis();
    })
  }

  @Builder
  private buildIdeaItem(idea: Idea): void {
    Row({ space: 8 }) {
      Checkbox()
        .select(this.state.isNoteSelected(idea.id))
        .selectedColor(this.app.theme.palette.primary)
        .width(20)
        .height(20)
        .onChange((checked: boolean) => {
          this.setNoteSelection(idea.id, checked);
        })

      Row() {
        Column({ space: 4 }) {
          Text(idea.title.length > 0 ? idea.title : '无标题')
            .fontSize(FormTypography.INPUT_CONTENT_SIZE)
            .fontColor(this.app.theme.palette.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(idea.content)
            .fontSize(FormTypography.LABEL_SIZE)
            .fontColor(this.app.theme.palette.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.formatTime(idea.timestamp))
          .fontSize(FormTypography.INFO_SIZE)
          .fontColor(this.app.theme.palette.textTertiary)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(() => {
        this.state.toggleNoteSelection(idea.id);
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.app.theme.palette.surfaceSecondary)
    .borderRadius(12)
  }

  build() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text("选择笔记")
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);
        
        this.buildStartButton();
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      Text(this.canStartAnalysis ? `已选 ${this.state.selectedNoteIds.length} 篇` : '未选择笔记')
        .fontSize(FormTypography.INFO_SIZE)
        .fontColor(this.app.theme.palette.textTertiary)
        .textAlign(TextAlign.Start)

      List({ space: 10 }) {
        ForEach(
          this.ideaState.ideas,
          (idea: Idea) => {
            ListItem() {
              this.buildIdeaItem(idea)
            }
          },
          (idea: Idea) => `selector_${idea.id}`,
        )
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .constraintSize({ maxHeight: '60%' })
  }
}
