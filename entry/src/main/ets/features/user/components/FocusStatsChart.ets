/**
 * 专注时长柱状图骨架。
 * TODO: 后续补充周/月统计和图表渲染。
 */
@Component
export struct FocusStatsChart {
  build() {
    Column({ space: 8 }) {
      Text('FocusStatsChart')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示专注时长统计图。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
