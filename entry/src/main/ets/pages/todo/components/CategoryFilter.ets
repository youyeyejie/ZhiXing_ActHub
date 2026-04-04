/**
 * 待办分类筛选骨架。
 * TODO: 后续补充横向滚动、选中态和颜色映射。
 */
@ComponentV2
export struct CategoryFilter {
  build() {
    Column({ space: 8 }) {
      Text('CategoryFilter')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 按分类筛选待办列表。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
