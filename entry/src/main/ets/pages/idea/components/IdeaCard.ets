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
  @Local private offsetX: number = 0;
  @Local private dragging: boolean = false;
  @Local private startX: number = 0;

  private repository: IdeaRepository = new IdeaRepository();
  private undoTimer: number = -1;

  // 滑动阈值
  private readonly SWIPE_THRESHOLD: number = 72;
  private readonly MAX_OFFSET: number = 96;

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
    this.offsetX = 0;

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

  /**
   * 处理触摸事件，实现滑动交互。
   */
  private handleTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.dragging = true;
      this.startX = event.touches[0].x;
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      const delta = event.touches[0].x - this.startX;
      // 只允许左滑（负值），右滑不超过 0
      this.offsetX = Math.max(-this.MAX_OFFSET, Math.min(0, delta));
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      const deltaX = event.touches.length > 0 ? event.touches[0].x - this.startX : this.offsetX;

      // 判断是否触发删除
      if (this.offsetX <= -this.SWIPE_THRESHOLD) {
        this.handleDelete();
      } else if (Math.abs(deltaX) < 10) {
        // 点击事件
        this.onTap(this.idea);
      }

      this.dragging = false;
      // 回弹动画
      this.offsetX = 0;
    }
  }

  aboutToDisappear(): void {
    if (this.undoTimer > 0) {
      clearTimeout(this.undoTimer);
      this.undoTimer = -1;
    }
  }

  build() {
    // 外层 Column 用于包裹撤销提示
    Column() {
      // 删除待确认期间隐藏卡片，只显示撤销提示（对齐设计文档：删除时先删除卡片）
      if (this.pendingDeleteId.length === 0) {
        // 使用 Stack 实现滑动删除
        Stack() {
          // 删除提示背景 - 放在 Stack 底层，左滑时露出
          Row() {
            Blank();
            Text('删除')
              .fontSize(14)
              .fontColor('#FFFFFF');
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FF4A4A')
          .borderRadius(20);

          // 卡片内容 - 可滑动，覆盖在背景上
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
          .translate({ x: this.offsetX, y: 0 })
          .animation({ duration: 180, curve: Curve.EaseOut, playMode: PlayMode.Normal })
          .onTouch((event: TouchEvent) => {
            this.handleTouch(event);
          });
        }
        .width('100%');
      }

      // 撤销提示 - 显示在卡片下方
      if (this.showUndo) {
        UndoNotification({
          message: '闪记已删除',
          durationMs: 5000,
          onUndo: () => {
            this.handleUndo();
          }
        })
          .margin({ top: 8 });
      }
    }
    .width('100%');
  }
}
