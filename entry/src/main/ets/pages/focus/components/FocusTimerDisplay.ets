import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';

/**
 * 专注计时显示核心组件。
 * 仅包含圆环进度、剩余时间、阶段名称。
 */
@ComponentV2
export struct FocusTimerDisplay {
  @Local private app: AppState = useAppState();
  /** 外部传入的专注计时引擎实例 */
  @Param engine: FocusTimerEngine = new FocusTimerEngine();

  build() {
    Column({ space: 0 }) {
      // 大圆环进度显示
      Stack({ alignContent: Alignment.Center }) {
        // 圆环进度组件 - 使用系统 Progress 组件 
        // todo: 美化，改成倒过来标志剩余时间？
        Progress({
          value: this.engine.getElapsedSeconds(),
          total: this.engine.totalSeconds,
          type: ProgressType.Ring
        })
          .width(238)
          .height(238)
          .color(this.app.theme.palette.primary)
          .style({ strokeWidth: 20, enableSmoothEffect: true })

        // 中心时间显示
        Column({ space: 4 }) {
          // 剩余时间 (MM:SS)
          Text(this.engine.getFormattedRemainingTime())
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .textAlign(TextAlign.Center)
            
          // 当前阶段名称
          Text(this.engine.getCurrentStageName())
            .fontSize(15)
            .fontColor(this.app.theme.palette.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width(238)
      .height(238)

    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
