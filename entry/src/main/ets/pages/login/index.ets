/**
 * 登录注册页骨架。
 * TODO: 后续区分登录和注册表单，并接入登录态保持。
 */
@ComponentV2
export struct LoginPage {
  build() {
    Column({ space: 12 }) {
      Text('登录 / 注册')
        .fontSize(24)
        .fontWeight(FontWeight.Bold);
      Text('TODO: 账号密码输入、登录注册切换。')
        .fontSize(14)
        .fontColor('#666666');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24);
  }
}
