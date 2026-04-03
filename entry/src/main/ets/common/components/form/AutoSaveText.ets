/**
 * 自动保存输入组件占位。
 * TODO: 后续补充防抖、保存状态提示和失焦提交逻辑。
 */
@Component
export struct AutoSaveText {
  build() {
    Column({ space: 8 }) {
      Text('AutoSaveText')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 输入停止后自动持久化。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor('#FFFFFF');
  }
}
