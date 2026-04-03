/**
 * 待办新建/编辑半屏页骨架。
 * TODO: 后续承载待办内容、分类和详情编辑字段。
 */
@Component
export struct TodoEditorSheet {
  build() {
    Column({ space: 8 }) {
      Text('TodoEditorSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载待办创建与详情编辑。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor('#FFFFFF');
  }
}
