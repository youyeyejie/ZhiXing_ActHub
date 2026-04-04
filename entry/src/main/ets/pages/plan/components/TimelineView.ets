import { AppState } from '../../../app/AppStates';

/**
 * 时间轴容器骨架。
 * TODO: 后续负责纵向时间刻度和日程卡片布局对齐。
 */
@ComponentV2
export struct TimelineView {
  @Consumer('appState') appState: AppState = new AppState();

  build() {
    Column({ space: 8 }) {
      Text('TimelineView')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载按时间排列的日程卡片。')
        .fontSize(12)
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.appState.theme.palette.surface);
  }
}
