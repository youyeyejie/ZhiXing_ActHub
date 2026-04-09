import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 专注计时面板组件，当前提供基础倒计时与开始/暂停演示。
 * - TODO: 尚未接入番茄钟状态机、休息阶段与后台计时。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染计时进度环、倒计时文本与控制按钮。
 *
 * 副作用：
 * - 按钮操作会启动/停止定时器并修改本地计时状态。
 * - `aboutToDisappear` 会清理定时器资源。
 */
@ComponentV2
export struct FocusTimerPanel {
  @Local private app: AppState = useAppState();
  @Local private total: number = 25*60; // 25分钟的总秒数
  @Local private value: number = 25*60; // 当前剩余秒数，初始为总秒数
  @Local private isStarted: boolean = false; // 是否正在计时
  private intervalId: number = -1; // 计时器ID

  aboutToDisappear() {
    // 组件销毁时清理计时器
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('FocusTimerPanel')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
      Button(this.isStarted ? '暂停' : '开始')
        .type(ButtonType.Circle)
        .width(56)
        .height(56)
        .fontSize(24)
        .stateEffect(true)
        .backgroundColor(this.app.theme.palette.primary)
        .fontColor(this.app.theme.palette.surface)
        .onClick(() => {
            if (this.isStarted) {
                // 暂停：清理计时器
                if (this.intervalId !== -1) {
                    clearInterval(this.intervalId);
                    this.intervalId = -1;
                }
                this.isStarted = false;
            } else {
                // 开始：启动计时器
                this.isStarted = true;
                this.intervalId = setInterval(() => {
                    this.value = Math.max(0, this.value - 60);
                }, 1000);
            }
        });            
      Stack() {
        Progress({ value: this.value, total: this.total, type: ProgressType.Ring })
          .width(180)
          .height(180)
          .color(this.app.theme.palette.primary)
          .style({ strokeWidth: 15, enableSmoothEffect: true });
        Column() {
          Text(`${Math.floor(this.value / 60).toString().padStart(2, '0')}:${(this.value % 60).toString().padStart(2, '0')}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.primary)
        }
      }
      .width(180)
      .height(180)
      Text('TODO: 展示倒计时与控制按钮。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
