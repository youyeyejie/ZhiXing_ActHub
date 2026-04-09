import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 可交互卡片基类，封装左右滑与点击手势识别。
 *
 * 可传入项：
 * - @Param leftHint/rightHint: 背景提示文案。
 * - @Param enableSwipeLeft/enableSwipeRight: 是否启用左右滑。
 * - @Param swipeThreshold/maxSwipeOffset: 手势触发阈值与最大偏移。
 * - @Event onSwipeLeft/onSwipeRight/onCardTap: 左滑、右滑、点击回调。
 * - @BuilderParam content: 卡片主体内容。
 *
 * 返回行为：
 * - 返回带手势响应和回弹动画的卡片容器。
 *
 * 副作用：
 * - 触摸事件会更新本地偏移状态并触发外部事件回调。
 */
@ComponentV2
export struct InteractableCard {
  @Local private app: AppState = useAppState();
  @Param leftHint: string = '左滑动作';
  @Param rightHint: string = '右滑动作';
  @Param enableSwipeLeft: boolean = false;
  @Param enableSwipeRight: boolean = false;
  @Param swipeThreshold: number = 72;
  @Param maxSwipeOffset: number = 96;
  @Event onSwipeLeft: () => void = () => {};
  @Event onSwipeRight: () => void = () => {};
  @Event onCardTap: () => void = () => {};

  @Local private offsetX: number = 0;
  @Local private startX: number = 0;
  @Local private startY: number = 0;
  @Local private dragging: boolean = false;

  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  private defaultContent() {
    Column({ space: 8 }) {
      Text('InteractableCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('左右滑动触发回调，松手后自动回弹。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .alignItems(HorizontalAlign.Start);
  }

  private resetOffset(): void {
    this.offsetX = 0;
  }

  private handleTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.dragging = true;
      this.startX = event.touches[0].x;
      this.startY = event.touches[0].y;
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      const rawDelta = event.touches[0].x - this.startX;
      let delta = rawDelta;
      if (!this.enableSwipeRight && delta > 0) {
        delta = 0;
      }
      if (!this.enableSwipeLeft && delta < 0) {
        delta = 0;
      }
      const maxOffset = this.maxSwipeOffset;
      this.offsetX = Math.max(-maxOffset, Math.min(maxOffset, delta));
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      const deltaX = event.touches.length > 0 ? event.touches[0].x - this.startX : this.offsetX;
      const deltaY = event.touches.length > 0 ? event.touches[0].y - this.startY : 0;
      const threshold = Math.max(24, this.swipeThreshold);
      if (this.enableSwipeLeft && this.offsetX <= -threshold) {
        this.onSwipeLeft();
      } else if (this.enableSwipeRight && this.offsetX >= threshold) {
        this.onSwipeRight();
      } else if (Math.abs(deltaX) < 10 && Math.abs(deltaY) < 10) {
        this.onCardTap();
      }

      this.dragging = false;
      this.resetOffset();
    }
  }

  build() {
    Stack() {
      Row() {
        Text(this.rightHint)
          .fontSize(12)
          .fontColor(this.app.theme.palette.primary);
        Blank();
        Text(this.leftHint)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textSecondary);
      }
      .width('100%')
      .padding({ left: 18, right: 18 });

      Column() {
        this.content();
      }
      .width('100%')
      .padding(16)
      .borderRadius(20)
      .backgroundColor(this.app.theme.palette.surface)
      .shadow({ radius: 12, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 4 })
      .translate({ x: this.offsetX, y: 0 })
      .animation({ duration: 180, curve: Curve.EaseOut, playMode: PlayMode.Normal })
      .onTouch((event: TouchEvent) => {
        this.handleTouch(event);
      });
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 });
  }
}
