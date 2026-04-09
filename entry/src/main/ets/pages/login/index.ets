import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 登录/注册页占位组件，用于后续承载认证表单流程。
 * - TODO: 尚未接入输入校验、注册切换与登录态持久化。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染全屏认证占位文案。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct LoginPage {
  @Local private app: AppState = useAppState();

  /**
   * 渲染登录/注册占位页。
   * TODO: 当前仅展示静态文案，尚未接入表单、校验和认证流程。
   */
  build() {
    Column({ space: 12 }) {
      Text('登录 / 注册')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.app.theme.palette.textPrimary);
      Text('TODO: 账号密码输入、登录注册切换。')
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
