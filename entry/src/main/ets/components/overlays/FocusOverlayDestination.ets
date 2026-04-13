import { AppState, useAppState } from '../../app/AppStates';
import { FocusPage } from '../../pages/focus';

/**
 * 组件功能简介：
 * - 专注页 overlay 路由容器，承载全屏 FocusPage 并处理返回。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回全屏目的页容器并渲染 FocusPage。
 *
 * 副作用：
 * - 关闭回调与返回键会调用 `app.nav.back(false)`。
 */
@ComponentV2
export struct FocusOverlayDestination {
  @Local private app: AppState = useAppState();

  private requestDismiss(): void {
    this.app.nav.back(false);
  }

  build() {
    NavDestination() {
      Column() {
        FocusPage({
          onRequestDismiss: () => {
            this.requestDismiss();
          },
        });
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .mode(NavDestinationMode.STANDARD)
    .onBackPressed(() => {
      this.requestDismiss();
      return true;
    });
  }
}
