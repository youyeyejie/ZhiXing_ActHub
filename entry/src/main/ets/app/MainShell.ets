import { BottomTabBar } from '../components/layout/BottomTabBar';
import { SafeAreaInsetLayout } from '../components/layout/SafeAreaInsetLayout';
import { AppRoute, AppTab } from './AppConstants';
import { AppState, useAppState } from './AppStates';
import { PlanPage } from '../pages/plan';
import { TodoPage } from '../pages/todo';
import { IdeaPage } from '../pages/idea';
import { UserPage } from '../pages/user';
import { SafeAreaUtils } from '../core/theme/SafeAreaUtils';

/**
 * 主应用壳层。
 * 负责底部四个主标签页的分发，以及专注入口等一级导航交互。
 */
@ComponentV2
export struct MainShell {
  @Local private app: AppState = useAppState();

  @Builder
  private buildCurrentTabPage() {
    if (this.app.nav.mainRouteName === AppRoute.PLAN) {
      PlanPage();
    } else if (this.app.nav.mainRouteName === AppRoute.TODO) {
      TodoPage();
    } else if (this.app.nav.mainRouteName === AppRoute.IDEA) {
      IdeaPage();
    } else {
      UserPage();
    }
  }

  build() {
    SafeAreaInsetLayout({
      includeTop: false,
      includeBottom: false,
      surfaceColor: this.app.theme.palette.background
    }) {
      Column({ space: 12 }) {
        Column() {
          this.buildCurrentTabPage();
        }
        .layoutWeight(1)
        .width('100%');

        BottomTabBar({
          currentTab: this.app.nav.currentTab(),
          onTabChange: (tab: AppTab): void => {
            this.app.nav.selectTab(tab);
          },
          onFocusTap: (): void => {
            this.app.nav.openFocus();
          }
        })
          .margin({ bottom: SafeAreaUtils.getBottomInset() });
      }
      .width('100%')
      .height('100%');
    }
  }
}
