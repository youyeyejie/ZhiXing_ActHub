import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';

/**
 * 专注计时显示核心组件。
 * 包含圆环进度、剩余时间、阶段名称。
 * 可传入项：
 * - 无。
 * - 副作用：无业务副作用。
 * todo：空闲状态下点击中央时间滑动弹出选择时间，美化圆环显示
 */

@ComponentV2
export struct FocusTimerDisplay {
  @Local private app: AppState = useAppState();
  @Require @Param engine: FocusTimerEngine;

  build() {
    Column({ space: 0 }) {
      // 大圆环进度显示
      Stack({ alignContent: Alignment.Center }) {
        // todo: 美化，第一次进入时主动渲染为满
        Progress({
          value: this.engine.getLeftSeconds(),
          total: this.engine.totalSeconds,
          type: ProgressType.Ring
        })
          .width(238)
          .height(238)
          .color(this.app.theme.palette.primary)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .style({ strokeWidth: 20, enableSmoothEffect: true })

        // 中心时间显示
        Column({ space: 4 }) {
          // 剩余时间 (MM:SS)
          // todo：空闲状态下，滑动番茄钟的数字选择开始时间
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
