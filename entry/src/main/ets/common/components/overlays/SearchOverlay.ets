/**
 * 搜索遮罩基类占位组件。
 * TODO: 后续接入输入框聚焦、软键盘唤起和页面遮罩动画。
 */
@Component
export struct SearchOverlay {
  build() {
    Column({ space: 8 }) {
      Text('SearchOverlay')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 在此统一处理页面搜索交互。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#F2F4F7');
  }
}
