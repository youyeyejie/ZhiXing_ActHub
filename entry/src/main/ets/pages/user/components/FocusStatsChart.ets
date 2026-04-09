import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 专注统计图占位组件。
 * - TODO: 尚未接入周/月维度统计与图表渲染。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染统计图占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct FocusStatsChart {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('FocusStatsChart')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示专注时长统计图。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
