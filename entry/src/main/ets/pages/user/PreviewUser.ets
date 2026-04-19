import { UserPage } from './index';

@Preview
/**
 * 组件功能简介：
 * - 我的页面预览组件，用于本地预览 `UserPage` 布局效果。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染完整用户页面。
 *
 * 副作用：
 * - 无。
 */
@ComponentV2
struct PreviewUserPage {
  build() {
    Column() {
      UserPage();
    }
    .width('100%')
    .height('100%');
  }
}
