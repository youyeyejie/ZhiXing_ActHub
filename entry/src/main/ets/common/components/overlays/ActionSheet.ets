/**
 * 半屏弹出容器占位组件。
 * TODO: 后续处理遮罩、键盘避让、高度自适应和弹出动画。
 */
@Component
export struct ActionSheet {
  build() {
    Column({ space: 8 }) {
      Text('ActionSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 在此承载新建和详情编辑表单。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor('#FFFFFF');
  }
}
