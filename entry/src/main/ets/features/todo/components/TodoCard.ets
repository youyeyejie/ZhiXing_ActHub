/**
 * 待办卡片骨架。
 * TODO: 后续补充勾选、右滑开启专注、左滑删除等交互。
 */
@Component
export struct TodoCard {
  build() {
    Column({ space: 8 }) {
      Text('TodoCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 显示待办内容、分类和勾选状态。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
