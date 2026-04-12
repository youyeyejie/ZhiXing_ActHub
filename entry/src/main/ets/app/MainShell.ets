import { BottomTabBar } from '../components/navigation/BottomTabBar';
import { SafeAreaInsetLayout } from '../components/layout/SafeAreaInsetLayout';
import { AppRoute, AppTab } from './AppConstants';
import { AppState, useAppState } from './AppStates';
import { PlanPage } from '../pages/plan';
import { PlanPageState, usePlanPageState } from '../pages/plan/PlanPageState';
import { TodoPage } from '../pages/todo';
import { TodoPageState, useTodoPageState } from '../pages/todo/TodoPageState';
import { IdeaPage } from '../pages/idea';
import { UserPage } from '../pages/user';
import { PlanEditorSheet } from '../pages/plan/components/PlanEditorSheet';
import { PlanDetailOverlay } from '../pages/plan/components/PlanDetailOverlay';
import { TodoEditorSheet } from '../pages/todo/components/TodoEditorSheet';
import { CategoryEditorOverlay } from '../pages/todo/components/CategoryEditorOverlay';
import { TodoDetailOverlay } from '../pages/todo/components/TodoDetailOverlay';

/**
 * 主应用壳层。
 * 负责底部四个主标签页的分发，以及专注入口等一级导航交互。
 */
@ComponentV2
export struct MainShell {
  @Local private app: AppState = useAppState();
  @Local private planState: PlanPageState = usePlanPageState();
  @Local private todoState: TodoPageState = useTodoPageState();

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
      includeTop: true,
      includeBottom: true,
      surfaceColor: this.app.theme.palette.background
    }) {
      Stack({ alignContent: Alignment.TopStart }) {
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
          });
        }
        .width('100%')
        .height('100%');

        if (this.planState.isEditorVisible) {
          PlanEditorSheet();
        }
        PlanDetailOverlay();

        if (this.todoState.isTodoEditorVisible) {
          TodoEditorSheet();
        }
        CategoryEditorOverlay();
        TodoDetailOverlay();
      }
      .width('100%')
      .height('100%');
    }
  }
}
