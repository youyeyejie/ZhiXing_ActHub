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
import display from '@ohos.display';

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
    this.applySafeInsets();
  }

  private applySafeInsets(): void {
    try {
      const info = display.getDefaultDisplaySync();
      const longEdge = Math.max(info.width, info.height);
      const shortEdge = Math.max(1, Math.min(info.width, info.height));
      const ratio = longEdge / shortEdge;

      if (ratio >= 2.18) {
        this.topInset = 48;
        this.bottomInset = 22;
      } else if (ratio >= 2.0) {
        this.topInset = 40;
        this.bottomInset = 18;
      } else {
        this.topInset = 30;
        this.bottomInset = 12;
      }
    } catch (_error) {
      this.topInset = 32;
      this.bottomInset = 12;
    }
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
    .backgroundColor('#F7F8FA');
  }

  build() {
    Navigation(this.appState.nav) {
      this.buildMainContent();
    }
    .title(AppConstants.APP_NAME)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .hideTitleBar(false)
    .width('100%')
    .height('100%');
  }
}
