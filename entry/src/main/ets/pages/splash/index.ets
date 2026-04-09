import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 启动页占位组件，用于承载冷启动阶段的品牌展示与预加载。
 * - TODO: 尚未接入本地数据、登录态和路由跳转逻辑。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染全屏启动文案占位布局。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct SplashPage {
  @Local private app: AppState = useAppState();

  /**
   * 渲染启动占位页。
   * TODO: 当前未执行资源预加载、路由跳转与冷启动检查。
   */
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
