import { AppState, useAppState } from '../../app/AppStates';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AIInsightState, useAIInsightState } from './AIInsightState';
import { IdeaPageState, useIdeaPageState } from '../idea/IdeaPageState';
import { AIInsightEntryCard } from './components/AIInsightEntryCard';
import { AIInsightHistoryList } from './components/AIInsightHistoryList';
import { AIInsightConversation } from './components/AIInsightConversation';
import { AIInsightNoteSelector } from './components/AIInsightNoteSelector';
import { UndoNotificationStack } from '../../components/feedback/UndoNotificationStack';

/**
 * AI 洞察中心主页面。
 * 首页展示功能入口卡片 + 历史列表，对话流展示生成过程。
 */
@ComponentV2
export struct AIInsightPage {
  @Local private app: AppState = useAppState();
  @Local private state: AIInsightState = useAIInsightState();
  @Local private ideaState: IdeaPageState = useIdeaPageState();
  @Param onRequestDismiss: () => void = () => {};

  aboutToAppear(): void {
    // 每次进入回到首页视图，但不打断后台生成
    this.state.viewMode = 'home';
    this.state.refreshRecords();
  }

  /**
   * 处理返回按钮。
   */
  private handleBack(): void {
    if (this.state.viewMode === 'conversation') {
      this.state.backToHome();
    } else {
      this.onRequestDismiss();
    }
  }

  /**
   * 打开笔记选择弹层。
   */
  private openNoteSelector(): void {
    if (this.state.isGenerating) {
      this.state.notifyGeneratingLocked();
      return;
    }
    this.state.resetSelection();
    this.app.nav.openActionSheet(this.buildNoteSelectorContent, 'auto');
  }

  @Builder
  private buildNoteSelectorContent() {
    AIInsightNoteSelector();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 0 }) {
        // 顶部安全区占位
        Row()
          .width('100%')
          .height(SafeAreaUtils.getTopInset())

        // 顶部导航栏
        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(20)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
              .fontColor([this.app.theme.palette.textPrimary]);
          }
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .backgroundColor(this.app.theme.palette.transparent)
          .onClick(() => {
            this.handleBack();
          })

          Text(this.state.viewMode === 'conversation' ? 'AI 洞察' : 'AI 洞察中心')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)

          Blank()
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 8 })

        Divider()
          .strokeWidth(0.5)
          .color(this.app.theme.palette.border)

        if (this.state.viewMode === 'home') {
          this.buildHomePage()
        } else {
          AIInsightConversation()
            .layoutWeight(1)
            .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background)

      UndoNotificationStack({
        tasks: this.state.buildUndoStackItems(),
        onUndo: (taskId: string) => {
          this.state.undoDelete(taskId);
        },
        onTimeout: (taskId: string) => {
          this.state.commitDeleteRecord(taskId);
        },
        onClose: (taskId: string) => {
          this.state.closeUndo(taskId);
        },
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHomePage() {
    Scroll() {
      Column({ space: 12 }) {
        // 功能入口卡片区
        Column({ space: 12 }) {
          // 全局洞察入口
          AIInsightEntryCard({
            icon: $r('sys.symbol.lightbulb'),
            title: '全量思维分析',
            description: '汇总所有笔记，发掘你的思维模式',
            disabled: this.ideaState.ideas.length === 0,
            onTap: () => {
              this.state.startGlobalInsight();
            },
          })

          // 精准洞察入口
          AIInsightEntryCard({
            icon: $r('sys.symbol.magnifyingglass'),
            title: '选中笔记对话',
            description: '针对特定内容进行精准分析',
            disabled: this.ideaState.ideas.length === 0,
            onTap: () => {
              this.openNoteSelector();
            },
          })
        }
        .padding({ left: 20, right: 20, top: 16 })

        // 历史列表
        Column() {
          AIInsightHistoryList()
        }
        .padding({ left: 20, right: 20, top: 8 })

        // 底部留白
        Column().height(40)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
}
