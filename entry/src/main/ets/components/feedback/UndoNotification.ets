import { AppState, useAppState } from "../../app/AppStates";

/**
 * 组件功能简介：
 * - 撤销提示条组件，提供倒计时进度、撤销按钮和自动关闭机制。
 *
 * 可传入项：
 * - @Param message/actionText: 提示文案与动作按钮文案。
 * - @Param durationMs: 自动关闭倒计时。
 * - @Event onUndo: 点击撤销时回调。
 * - @Event onTimeout: 倒计时结束时回调。
 * - @Event onClose: 组件关闭时回调（撤销或超时都会触发）。
 *
 * 返回行为：
 * - 返回一条带胶囊进度按钮的通知条。
 *
 * 副作用：
 * - 组件生命周期会启动/停止计时器并触发外部回调。
 */
@ComponentV2
export struct UndoNotification {
  @Local private app: AppState = useAppState();
  @Param message: string = "操作已执行";
  @Param actionText: string = "撤销";
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
      this.remainMs = this.remainMs - 10;
      if (this.remainMs <= 0) {
        this.stopCountdown();
        this.onTimeout();
        this.onClose();
      }
    }, 10);
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
          .fontColor(this.app.theme.palette.textPrimary)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Capsule })
          .width(60)
          .height(30)
          .color(this.app.theme.palette.primary)
          .style({
            strokeWidth: 3,
            enableSmoothEffect: true,
            content: this.actionText,
            font: { size: 13, style: FontStyle.Normal },
            fontColor: this.app.theme.palette.textPrimary,
          })
          .onClick(() => {
            this.stopCountdown();
            this.onUndo();
            this.onClose();
          })
      }.width("100%")
    }
    .width("100%")
    .padding(16)
    .borderRadius(18)
    .backgroundColor(this.app.theme.palette.surfaceSecondary)
    .shadow({ radius: 10, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 3 });
  }
}
