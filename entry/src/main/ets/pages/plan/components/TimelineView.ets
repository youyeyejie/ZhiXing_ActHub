import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 日程时间轴占位组件，预留按时间排列日程卡片能力。
 * - TODO: 尚未接入刻度计算、冲突布局和吸附滚动。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染时间轴占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct TimelineView {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('TimelineView')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载按时间排列的日程卡片。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
