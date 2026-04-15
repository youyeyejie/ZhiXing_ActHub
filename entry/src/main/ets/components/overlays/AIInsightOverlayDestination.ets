import { AppState, useAppState } from '../../app/AppStates';
import { AIInsightPage } from '../../pages/idea/components/AIInsightPanel';

/**
 * AI 洞察页 overlay 路由容器，承载全屏 AIInsightPage 并处理返回。
 */
@ComponentV2
export struct AIInsightOverlayDestination {
  @Local private app: AppState = useAppState();

  private requestDismiss(): void {
    // 先清空 overlay 状态，再执行返回
    this.app.nav.hasOverlayRoute = false;
    this.app.nav.back(false);
  }

  build() {
    NavDestination() {
      AIInsightPage({
        onRequestDismiss: () => {
          this.requestDismiss();
        },
      });
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .mode(NavDestinationMode.STANDARD)
    .onBackPressed(() => {
      this.requestDismiss();
      return true;
    });
  }
}
