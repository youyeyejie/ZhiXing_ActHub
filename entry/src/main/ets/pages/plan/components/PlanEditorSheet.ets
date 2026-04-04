/**
 * 日程新建/编辑半屏页骨架。
 * TODO: 后续组合 ActionSheet 与 AutoSaveText 完成表单编辑。
 */
@ComponentV2
export struct PlanEditorSheet {
  build() {
    Column({ space: 8 }) {
      Text('PlanEditorSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载日程字段编辑表单。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor('#FFFFFF');
  }
}
