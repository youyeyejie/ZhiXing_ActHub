import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 周视图日历骨架。
 * TODO: 后续补充横向滑动、周吸附、双击回今日与选中态同步。
 */
@ComponentV2
export struct WeekCalendar {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('WeekCalendar')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示一周日期并响应手势切换。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
