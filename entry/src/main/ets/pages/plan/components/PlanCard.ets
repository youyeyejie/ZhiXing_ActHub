import { AppState, useAppState } from '../../../app/AppStates';
import { InteractableCard } from '../../../components/card/InteractableCard';

/**
 * 组件功能简介：
 * - 日程卡片占位组件，用于承载单条日程信息展示。
 * - TODO: 尚未接入时间、地点、类型与交互行为。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染一张占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct PlanCard {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('PlanCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 显示日程标题、时间段和地点。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
