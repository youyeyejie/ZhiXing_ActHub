import { AppTab } from './AppConstants';
import { SafeAreaUtils } from '../core/theme/SafeAreaUtils';
import { AppFlow, AppRoute } from './AppConstants';
import { AppState, useAppState } from './AppStates';
import { MainShell } from './MainShell';
import { SplashPage } from '../pages/splash';
import { LoginPage } from '../pages/login';
import { FocusDestinationPage } from '../pages/navigation/FocusDestinationPage';
import { SearchPlaceholderPage } from '../pages/navigation/SearchPlaceholderPage';
import { DetailPlaceholderPage } from '../pages/navigation/DetailPlaceholderPage';
import { SettingsPlaceholderPage } from '../pages/navigation/SettingsPlaceholderPage';
import { SharedTestDestinationPage } from '../pages/navigation/SharedTestDestinationPage';

/**
 * 应用总壳层。
 * 负责分发启动、登录与主壳流程，并承载进入式页面路由。
 */
@ComponentV2
export struct AppShell {
  @Local private app: AppState = useAppState();
  @Local private currentTab: AppTab = AppTab.PLAN;
  @Local private topInset: number = 30;
  @Local private bottomInset: number = 12;

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getTopInset();
    this.bottomInset = SafeAreaUtils.getBottomInset();
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
      FocusDestinationPage();
    } else if (
      name === AppRoute.PLAN_SEARCH ||
      name === AppRoute.TODO_SEARCH ||
      name === AppRoute.IDEA_SEARCH
    ) {
      SearchPlaceholderPage({ routeName: name });
    } else if (
      name === AppRoute.PLAN_DETAIL ||
      name === AppRoute.TODO_DETAIL ||
      name === AppRoute.IDEA_DETAIL
    ) {
      DetailPlaceholderPage({ routeName: name });
    } else if (name === AppRoute.USER_SETTINGS) {
      SettingsPlaceholderPage();
    } else if (name === AppRoute.SHARED_TEST) {
      SharedTestDestinationPage();
    } else {
      SearchPlaceholderPage({ routeName: name });
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
    .backgroundColor('#F7F8FA');
  }
}
