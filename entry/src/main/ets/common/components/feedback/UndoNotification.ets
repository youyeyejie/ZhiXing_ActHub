/**
 * 撤销提示条占位组件。
 * TODO: 后续接入倒计时进度、撤销回调和自动关闭机制。
 */
@Component
export struct UndoNotification {
  build() {
    Row({ space: 12 }) {
      Text('UndoNotification')
        .fontSize(14)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 显示剩余撤销时间。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor('#1F2937');
  }
}
