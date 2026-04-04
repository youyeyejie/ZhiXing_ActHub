import { AppShell } from '../app/AppShell';
import '../pages/login'
/**
 * 应用根页面。
 * 当前阶段只负责挂载整体壳层，不承载任何业务逻辑。
 */
@Entry
@ComponentV2
struct Index {
  build() {
    Column() {
      AppShell();
    }
    .width('100%')
    .height('100%');
  }
}
