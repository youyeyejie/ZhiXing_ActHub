/**
 * 内容流容器骨架。
 * TODO: 后续负责同类卡片的懒加载、分页和统一间距管理。
 */
@Component
export struct ContentFlow {
  build() {
    Column({ space: 8 }) {
      Text('ContentFlow')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载页面内容列表与懒加载逻辑。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
