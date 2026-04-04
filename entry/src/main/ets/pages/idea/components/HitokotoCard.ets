import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 一言卡片骨架。
 * TODO: 后续接入网络文案获取和本地句库回退。
 */
@ComponentV2
export struct HitokotoCard {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('HitokotoCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示随机句子或本地回退文案。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
