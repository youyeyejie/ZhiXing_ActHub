import { Idea } from '../../../core/models/Idea';
import { AppState, useAppState } from '../../../app/AppStates';
import { UndoNotification } from '../../../components/feedback/UndoNotification';
import { IdeaRepository } from '../../../core/repositories/IdeaRepository';

/**
 * 闪记卡片组件。
 * 支持显示标题、内容摘要、创建时间，提供左滑删除交互。
 */
@ComponentV2
export struct IdeaCard {
  @Local private app: AppState = useAppState();
  @Param idea: Idea = new Idea();
  @Event onDelete: (idea: Idea) => void = (_idea: Idea) => {};
  @Event onTap: (idea: Idea) => void = (_idea: Idea) => {};

  @Local private showUndo: boolean = false;
  @Local private pendingDeleteId: string = '';
  private repository: IdeaRepository = new IdeaRepository();
  private undoTimer: number = -1;

  /**
   * 格式化时间显示。
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const isYesterday = date.toDateString() === yesterday.toDateString();

    const timeStr = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;

    if (isToday) {
      return `今天 ${timeStr}`;
    }
    if (isYesterday) {
      return `昨天 ${timeStr}`;
    }
    return `${date.getMonth() + 1}/${date.getDate()} ${timeStr}`;
  }

  /**
   * 处理删除操作。
   */
  private handleDelete(): void {
    this.pendingDeleteId = this.idea.id;
    this.showUndo = true;

    // 5 秒后真正删除
    this.undoTimer = setTimeout(() => {
      this.repository.removeById(this.pendingDeleteId).then(() => {
        this.onDelete(this.idea);
      });
      this.showUndo = false;
      this.pendingDeleteId = '';
    }, 5000);
  }

  /**
   * 撤销删除。
   */
  private handleUndo(): void {
    if (this.undoTimer > 0) {
      clearTimeout(this.undoTimer);
      this.undoTimer = -1;
    }
    this.showUndo = false;
    this.pendingDeleteId = '';
  }

  aboutToDisappear(): void {
    if (this.undoTimer > 0) {
      clearTimeout(this.undoTimer);
      this.undoTimer = -1;
    }
  }

  build() {
    Stack() {
      // 背景提示
      Row() {
        Blank();
        Text('删除')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding({ left: 24, right: 24 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FF4A4A')
      .borderRadius(20);

      // 卡片内容
      Column({ space: 8 }) {
        // 标题（可选）
        if (this.idea.title && this.idea.title.length > 0) {
          Text(this.idea.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }

        // 内容（带省略号）
        Text(this.idea.content)
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        // 时间信息
        Text(this.formatTime(this.idea.timestamp))
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
          .margin({ top: 4 });
      }
      .width('100%')
      .padding(16)
      .borderRadius(20)
      .backgroundColor(this.app.theme.palette.surface)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        this.onTap(this.idea);
      });

      // 撤销提示
      if (this.showUndo) {
        UndoNotification({
          message: '闪记已删除',
          durationMs: 5000,
          onUndo: () => {
            this.handleUndo();
          }
        });
      }
    }
    .width('100%')
    .height('auto')
    .gesture(
      PanGesture()
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetX <= -72) {
            this.handleDelete();
          }
        })
    );
  }
}
