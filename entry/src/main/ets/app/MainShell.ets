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
 * 组件功能简介：
 * - 主流程壳层，负责四个主标签页内容分发与底部栏展示。
 *
 * 可传入项：
 * - 无（通过 AppState 读取当前主路由与主题状态）。
 *
 * 返回行为：
 * - 返回带安全区处理的页面容器，内部按当前路由渲染对应模块页面。
 *
 * 副作用：
 * - 底部栏交互会触发 AppNav 的路由切换与专注页打开。
 */
@ComponentV2
export struct MainShell {
  @Local private app: AppState = useAppState();

  @Builder
  /**
   * 根据当前主路由渲染对应标签页内容。
   */
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

  /**
   * 渲染主壳层页面与底部导航栏。
   */
  build() {
    SafeAreaInsetLayout({
      includeTop: false,
      includeBottom: false,
      surfaceColor: this.app.theme.palette.background
    }) {
      Column() {
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
          .margin({ bottom: SafeAreaUtils.getBottomInset()-6 });
      }
      .width('100%')
      .height('100%');
    }
  }
}
