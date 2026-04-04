import { AppState } from '../../app/AppStates';

/**
 * 启动页骨架。
 * TODO: 后续加载本地数据、主题和登录态，再跳转主流程。
 */
@ComponentV2
export struct SplashPage {
  @Consumer('appState') appState: AppState = new AppState();

  build() {
    Column({ space: 12 }) {
      Text('启动页')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.appState.theme.palette.textPrimary);
      Text('TODO: Logo 展示与后台预加载。')
        .fontSize(14)
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
    .backgroundColor(this.appState.theme.palette.background);
  }
}
