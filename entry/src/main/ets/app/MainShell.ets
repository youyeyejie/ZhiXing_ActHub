import display from '@ohos.display';
import { BottomTabBar } from '../components/navigation/BottomTabBar';
import { AppTab } from './AppConstants';
import { AppState, useAppState } from './AppStates';
import { PlanPage } from '../pages/plan';
import { TodoPage } from '../pages/todo';
import { IdeaPage } from '../pages/idea';
import { UserPage } from '../pages/user';

/**
 * 主应用壳层。
 * 负责底部四个主标签页的分发，以及专注入口等一级导航交互。
 */
@ComponentV2
export struct MainShell {
  @Local private app: AppState = useAppState();
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
  private buildCurrentTabPage() {
    if (this.app.nav.selectedTab === AppTab.PLAN) {
      PlanPage();
    } else if (this.app.nav.selectedTab === AppTab.TODO) {
      TodoPage();
    } else if (this.app.nav.selectedTab === AppTab.IDEA) {
      IdeaPage();
    } else {
      UserPage();
    }
  }

  build() {
    Column({ space: 12 }) {
      Column() {
        this.buildCurrentTabPage();
      }
      .layoutWeight(1)
      .width('100%');

      BottomTabBar({
        currentTab: this.app.nav.selectedTab,
        onTabChange: (tab: AppTab): void => {
          this.app.nav.selectTab(tab);
        },
        onFocusTap: (): void => {
          this.app.nav.openFocus();
        }
      });
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.topInset, bottom: this.bottomInset })
    .backgroundColor('#F7F8FA');
  }
}
