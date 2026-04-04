import { BottomTabBar } from '../components/navigation/BottomTabBar';
import { AppConstants } from './AppConstants';
import { AppTab } from './AppConstants';
import { AppState } from './AppStates';
import { PlanPage } from '../pages/plan';
import { TodoPage } from '../pages/todo';
import { FocusPage } from '../pages/focus';
import { IdeaPage } from '../pages/idea';
import { UserPage } from '../pages/user';
import { SharedInteractionTestPage } from '../pages/sharedtest';
import { SafeAreaUtils } from '../core/theme/SafeAreaUtils';

/**
 * 应用总壳层。
 * 当前阶段改用 Navigation 承载主页面，后续在此继续接入登录态分发与全局 Overlay 容器。
 */
@ComponentV2
export struct AppShell {
  @Provider('appState') appState: AppState = new AppState();
  @Local private currentTab: AppTab = AppTab.PLAN;
  @Local private topInset: number = 30;
  @Local private bottomInset: number = 12;

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getTopInset();
    this.bottomInset = SafeAreaUtils.getBottomInset();
  }

  @Builder
  private buildCurrentPage() {
    if (this.currentTab === AppTab.PLAN) {
      PlanPage();
    } else if (this.currentTab === AppTab.TODO) {
      TodoPage();
    } else if (this.currentTab === AppTab.FOCUS) {
      FocusPage();
    } else if (this.currentTab === AppTab.IDEA) {
      IdeaPage();
    } else if (this.currentTab === AppTab.TEST) {
      SharedInteractionTestPage();
    } else {
      UserPage();
    }
  }

  @Builder
  private buildMainContent() {
    Column({ space: 12 }) {
      Column() {
        this.buildCurrentPage();
      }
      .layoutWeight(1)
      .width('100%');

      BottomTabBar({
        currentTab: this.currentTab,
        onTabChange: (tab: AppTab): void => {
          this.currentTab = tab;
        }
      });
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.topInset, bottom: this.bottomInset })
    .backgroundColor(this.appState.theme.palette.background);
  }

  build() {
    Navigation(this.appState.nav) {
      this.buildMainContent();
    }
    .title(AppConstants.APP_NAME)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .hideTitleBar(true)
    .width('100%')
    .height('100%');
  }
}
