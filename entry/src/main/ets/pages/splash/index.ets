import { AppState, useAppState } from '../../app/AppStates';

/**
 * 启动页骨架。
 * TODO: 后续加载本地数据、主题和登录态，再跳转主流程。
 */
@ComponentV2
export struct SplashPage {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 12 }) {
      Text('启动页')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.app.theme.palette.textPrimary);
      Text('TODO: Logo 展示与后台预加载。')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
    .backgroundColor(this.app.theme.palette.background);
  }
}
