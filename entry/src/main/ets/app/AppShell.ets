import { BottomTabBar } from '../common/components/navigation/BottomTabBar';
import { AppConstants } from '../common/constants/AppConstants';
import { AppTab } from '../common/types/AppEnums';
import { PlanPage } from '../features/plan/pages/PlanPage';
import { TodoPage } from '../features/todo/pages/TodoPage';
import { FocusPage } from '../features/focus/pages/FocusPage';
import { IdeaPage } from '../features/idea/pages/IdeaPage';
import { UserPage } from '../features/user/pages/UserPage';
import { SharedInteractionTestPage } from '../features/sharedtest/pages/SharedInteractionTestPage';
import display from '@ohos.display';

/**
 * 应用总壳层。
 * 当前阶段改用 Navigation 承载主页面，后续在此继续接入登录态分发与全局 Overlay 容器。
 */
@Component
export struct AppShell {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @State private topInset: number = 30;
  @State private bottomInset: number = 12;
  @State private currentTab: AppTab = AppTab.PLAN;

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
  private pageMap(name: string) {
    if (name === AppTab.PLAN) {
      PlanPage();
    } else if (name === AppTab.TODO) {
      TodoPage();
    } else if (name === AppTab.FOCUS) {
      FocusPage();
    } else if (name === AppTab.IDEA) {
      IdeaPage();
    } else if (name === AppTab.USER) {
      UserPage();
    } else if (name === AppTab.TEST) {
      SharedInteractionTestPage();
    }
  }

  build() {
    Navigation(this.navPathStack) {
      this.buildMainContent();
    }
    .title(AppConstants.APP_NAME)
    .mode(NavigationMode.Stack)
    .navDestination(this.pageMap)
    .hideBackButton(true)
    .hideTitleBar(false)
    .width('100%')
    .height('100%');
  }
}
