/**
 * 周视图日历骨架。
 * TODO: 后续补充横向滑动、周吸附、双击回今日与选中态同步。
 */
@Component
export struct WeekCalendar {
  build() {
    Column({ space: 8 }) {
      Text('WeekCalendar')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示一周日期并响应手势切换。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
