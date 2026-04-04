import { AppState } from '../../app/AppStates';

/**
 * 撤销提示条。
 * 提供倒计时进度、撤销动作和自动关闭。
 */
@ComponentV2
export struct UndoNotification {
  @Consumer('appState') appState: AppState = new AppState();
  @Param message: string = '操作已执行';
  @Param actionText: string = '撤销';
  @Param durationMs: number = 5000;
  @Event onUndo: () => void = () => {};
  @Event onTimeout: () => void = () => {};
  @Event onClose: () => void = () => {};

  @Local private remainMs: number = 0;
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
          .fontColor(this.appState.theme.palette.surface)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1);

        Text(this.actionText)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.appState.theme.palette.primary)
          .onClick(() => {
            this.stopCountdown();
            this.onUndo();
            this.onClose();
          });
      }
      .width('100%');

      Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .color(this.appState.theme.palette.primary)
        .style({ strokeWidth: 3 });
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(this.appState.theme.palette.surfaceSecondary)
    .shadow({ radius: 10, color: this.appState.theme.palette.mask, offsetX: 0, offsetY: 3 });
  }
}
