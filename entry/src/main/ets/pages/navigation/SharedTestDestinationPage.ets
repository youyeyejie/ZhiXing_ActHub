import { AppState, useAppState } from '../../app/AppStates';
import { SafeAreaInsetLayout } from '../../components/layout/SafeAreaInsetLayout';
import { SharedInteractionTestPage } from '../sharedtest';

/**
 * 共享测试页路由容器。
 * 通过 NavDestination 承载测试页，避免普通页面直接作为目的页时出现空白节点。
 */
@ComponentV2
export struct SharedTestDestinationPage {
  @Local private app: AppState = useAppState();

  build() {
    NavDestination() {
      SafeAreaInsetLayout({
        includeTop: true,
        surfaceColor: this.app.theme.palette.background
      }) {
        SharedInteractionTestPage();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .onBackPressed(() => {
      this.app.nav.back();
      return true;
    });
  }
}

@Builder
export function SharedTestDestinationPageBuilder(_name: string, _param: Object) {
  SharedTestDestinationPage();
}
