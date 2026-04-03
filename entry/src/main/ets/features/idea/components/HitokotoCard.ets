/**
 * 一言卡片骨架。
 * TODO: 后续接入网络文案获取和本地句库回退。
 */
@Component
export struct HitokotoCard {
  build() {
    Column({ space: 8 }) {
      Text('HitokotoCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示随机句子或本地回退文案。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
