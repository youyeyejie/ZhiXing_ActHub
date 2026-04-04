import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 专注时长柱状图骨架。
 * TODO: 后续补充周/月统计和图表渲染。
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
