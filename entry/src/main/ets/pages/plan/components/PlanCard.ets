import { AppState } from '../../../app/AppStates';

/**
 * 日程卡片骨架。
 * TODO: 后续在此继承通用卡片交互并呈现时间、地点与类型。
 */
@ComponentV2
export struct PlanCard {
  @Consumer('appState') appState: AppState = new AppState();

  build() {
    Column({ space: 8 }) {
      Text('PlanCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 显示日程标题、时间段和地点。')
        .fontSize(12)
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.appState.theme.palette.surface);
  }
}
