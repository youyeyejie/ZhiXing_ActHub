import { AppShell } from '../app/AppShell';
import '../pages/login'
/**
 * 组件功能简介：
 * - 应用根组件入口，仅负责挂载 `AppShell`。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染一个全屏容器并在其中放置应用壳层。
 *
 * 副作用：
 * - 无业务副作用。
 */
@Entry
@ComponentV2
struct Index {
  /**
   * 挂载应用壳层入口。
   */
  build() {
    Column() {
      AppShell();
    }
    .width('100%')
    .height('100%');
  }
}
