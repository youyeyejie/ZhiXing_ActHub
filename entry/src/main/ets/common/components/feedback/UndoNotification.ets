/**
 * 撤销提示条。
 * 提供倒计时进度、撤销动作和自动关闭。
 */
@Component
export struct UndoNotification {
  @Prop message: string = '操作已执行';
  @Prop actionText: string = '撤销';
  @Prop durationMs: number = 5000;
  onUndo: () => void = () => {};
  onTimeout: () => void = () => {};
  onClose: () => void = () => {};

  @State private remainMs: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.startCountdown();
  }

  aboutToDisappear(): void {
    this.stopCountdown();
  }

  private stopCountdown(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private startCountdown(): void {
    this.stopCountdown();
    this.remainMs = Math.max(1000, this.durationMs);
    this.timerId = setInterval(() => {
      this.remainMs = this.remainMs - 100;
      if (this.remainMs <= 0) {
        this.stopCountdown();
        this.onTimeout();
        this.onClose();
      }
    }, 100);
  }

  private getProgressPercent(): number {
    const duration = Math.max(1000, this.durationMs);
    const ratio = this.remainMs / duration;
    return Math.max(0, Math.min(100, ratio * 100));
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Text(this.message)
          .fontSize(14)
          .fontColor('#F9FAFB')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1);

        Text(this.actionText)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#86EFAC')
          .onClick(() => {
            this.stopCountdown();
            this.onUndo();
            this.onClose();
          });
      }
      .width('100%');

      Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .color('#86EFAC')
        .style({ strokeWidth: 3 });
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor('#1F2937')
    .shadow({ radius: 10, color: '#1A000000', offsetX: 0, offsetY: 3 });
  }
}
