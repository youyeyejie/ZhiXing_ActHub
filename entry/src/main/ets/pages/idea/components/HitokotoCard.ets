import { AppState } from '../../../app/AppStates';

/**
 * 一言卡片骨架。
 * TODO: 后续接入网络文案获取和本地句库回退。
 */
@ComponentV2
export struct HitokotoCard {
  @Consumer('appState') appState: AppState = new AppState();

  build() {
    Column({ space: 8 }) {
      Text('HitokotoCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示随机句子或本地回退文案。')
        .fontSize(12)
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.appState.theme.palette.surface);
  }
}
