/**
 * 可交互卡片基类。
 * 提供统一圆角、阴影与左右滑动手势回调。
 */
@ComponentV2
export struct InteractableCard {
  @Param leftHint: string = '左滑动作';
  @Param rightHint: string = '右滑动作';
  @Param swipeThreshold: number = 72;
  @Param maxSwipeOffset: number = 96;
  @Event onSwipeLeft: () => void = () => {};
  @Event onSwipeRight: () => void = () => {};

  @Local private offsetX: number = 0;
  @Local private startX: number = 0;
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
        .fontColor('#666666');
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
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      const delta = event.touches[0].x - this.startX;
      const maxOffset = this.maxSwipeOffset;
      this.offsetX = Math.max(-maxOffset, Math.min(maxOffset, delta));
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      const threshold = Math.max(24, this.swipeThreshold);
      if (this.offsetX <= -threshold) {
        this.onSwipeLeft();
      } else if (this.offsetX >= threshold) {
        this.onSwipeRight();
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
          .fontColor('#0A7C3B');
        Blank();
        Text(this.leftHint)
          .fontSize(12)
          .fontColor('#B42318');
      }
      .width('100%')
      .padding({ left: 18, right: 18 });

      Column() {
        this.content();
      }
      .width('100%')
      .padding(16)
      .borderRadius(20)
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 12, color: '#1A0F172A', offsetX: 0, offsetY: 4 })
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
