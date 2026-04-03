/**
 * 启动页骨架。
 * TODO: 后续加载本地数据、主题和登录态，再跳转主流程。
 */
@Component
export struct SplashPage {
  build() {
    Column({ space: 12 }) {
      Text('启动页')
        .fontSize(24)
        .fontWeight(FontWeight.Bold);
      Text('TODO: Logo 展示与后台预加载。')
        .fontSize(14)
        .fontColor('#666666');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24);
  }
}
