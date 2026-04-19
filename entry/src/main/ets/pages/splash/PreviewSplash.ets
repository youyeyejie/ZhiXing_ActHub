import { SplashPage } from './index';

@Preview
/**
 * 组件功能简介：
 * - 启动页预览组件，用于本地预览 `SplashPage` 外观。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染完整启动页布局。
 *
 * 副作用：
 * - 无。
 */
@ComponentV2
struct PreviewSplashPage {
  build() {
    Column() {
      SplashPage();
    }
    .width('100%')
    .height('100%');
  }
}
