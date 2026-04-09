import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 周视图日历占位组件，预留周切换与日期选中能力。
 * - TODO: 尚未接入横滑切周、回到今日和选中态同步。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染周历占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
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
