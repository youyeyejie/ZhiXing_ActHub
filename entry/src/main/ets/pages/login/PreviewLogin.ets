import { LoginPage } from './index';

@Preview
/**
 * 组件功能简介：
 * - 登录页预览组件，用于本地 UI 预览验证。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染 `LoginPage` 的完整界面。
 *
 * 副作用：
 * - 无。
 */
@ComponentV2
struct PreviewLoginPage {
  build() {
    Column() {
      LoginPage();
    }
    .width('100%')
    .height('100%');
  }
}
