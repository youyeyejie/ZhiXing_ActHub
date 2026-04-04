import { BottomTabBar } from '../components/navigation/BottomTabBar';
import { AppTab } from './AppConstants';
import { AppState, useAppState } from './AppStates';
import { SafeAreaUtils } from '../core/theme/SafeAreaUtils';
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
  @Local private topInset: number = SafeAreaUtils.getTopInset();
  @Local private bottomInset: number = SafeAreaUtils.getBottomInset();

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getTopInset();
    this.bottomInset = SafeAreaUtils.getBottomInset();
  }

  private resolveTabByIndex(index: number): AppTab {
    if (index === 0) {
      return AppTab.PLAN;
    }
    if (index === 1) {
      return AppTab.TODO;
    }
    if (index === 2) {
      return AppTab.IDEA;
    }
    return AppTab.USER;
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
    .backgroundColor(this.app.theme.palette.background);
  }
}
