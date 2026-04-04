import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 时间轴容器骨架。
 * TODO: 后续负责纵向时间刻度和日程卡片布局对齐。
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
