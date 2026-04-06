import { AppFlow, AppOverlayRoute, AppRoute } from './AppConstants';
import { AppState, useAppState } from './AppStates';
import { MainShell } from './MainShell';
import { SplashPage } from '../pages/splash';
import { LoginPage } from '../pages/login';
import { SharedTestDestinationPage } from '../pages/sharedtest/SharedTestDestinationPage';
import { FocusOverlayDestination, SearchOverlayDestination } from '../components/navigation/OverlayDestinations';
import { SearchRouteParam } from './AppConstants';

/**
 * 应用总壳层。
 * 负责分发启动、登录与主壳流程，并承载进入式页面路由。
 */
@ComponentV2
export struct AppShell {
  @Local private app: AppState = useAppState();

  private createFallbackSearchParam(routeName: string): SearchRouteParam {
    return new SearchRouteParam(routeName, '搜索');
  }

  @Builder
  private buildBaseContent() {
    if (this.app.flow === AppFlow.SPLASH) {
      SplashPage();
    } else if (this.app.flow === AppFlow.AUTH) {
      LoginPage();
    } else {
      MainShell();
    }
  }

  @Builder
  private buildDestination(name: string) {
    if (name === AppRoute.FOCUS) {
      FocusOverlayDestination();
    } else if (name === AppOverlayRoute.SEARCH) {
      SearchOverlayDestination({ routeParam: this.createFallbackSearchParam(name) });
    } else if (name === AppOverlayRoute.SHARED_TEST) {
      SharedTestDestinationPage();
    } else {
      SearchOverlayDestination({ routeParam: this.createFallbackSearchParam(name) });
    }
  }

  build() {
    Stack() {
      this.buildBaseContent();

      if (this.app.nav.hasOverlayRoute) {
        Navigation(this.app.nav) {
        }
        .mode(NavigationMode.Stack)
        .hideNavBar(true)
        .navDestination(this.buildDestination)
        .backgroundColor(Color.Transparent)
        .width('100%')
        .height('100%');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
