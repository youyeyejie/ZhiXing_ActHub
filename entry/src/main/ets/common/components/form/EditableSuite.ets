/**
 * 自动保存编辑套件骨架。
 * TODO: 后续统一聚合文本编辑、自动保存状态和错误提示。
 */
@Component
export struct EditableSuite {
  build() {
    Column({ space: 8 }) {
      Text('EditableSuite')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 作为详情页编辑能力的通用外壳。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
