/**
 * 闪记卡片骨架。
 * TODO: 后续补充标题、省略内容、创建时间和点击展开详情。
 */
@ComponentV2
export struct IdeaCard {
  build() {
    Column({ space: 8 }) {
      Text('IdeaCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示标题、正文摘要和时间信息。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
