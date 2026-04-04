import { AppRoute, AppTab, DetailRouteParam, SearchRouteParam } from './AppConstants';

/**
 * 应用主导航状态。
 * 基于 Navigation 控制器扩展应用级导航能力。
 * 当前 MVP 阶段负责维护主标签页状态，并为后续搜索、详情和专注页提供统一入口。
 */
@ObservedV2
export class AppNav extends NavPathStack {
  @Trace public selectedTab: AppTab = AppTab.PLAN;
  @Trace public hasOverlayRoute: boolean = false;

  selectTab(tab: AppTab): void {
    this.selectedTab = tab;
  }

  openFocus(): void {
    this.hasOverlayRoute = true;
    this.pushPath({ name: AppRoute.FOCUS });
  }

  openPlanSearch(): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: AppRoute.PLAN_SEARCH,
      param: new SearchRouteParam('plan', '搜索日程')
    });
  }

  openTodoSearch(): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: AppRoute.TODO_SEARCH,
      param: new SearchRouteParam('todo', '搜索待办')
    });
  }

  openIdeaSearch(): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: AppRoute.IDEA_SEARCH,
      param: new SearchRouteParam('idea', '搜索闪记')
    });
  }

  openUserSettings(): void {
    this.hasOverlayRoute = true;
    this.pushPath({ name: AppRoute.USER_SETTINGS });
  }

  openSharedTest(): void {
    this.hasOverlayRoute = true;
    this.pushPath({ name: AppRoute.SHARED_TEST });
  }

  openPlanDetail(planId: string): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: AppRoute.PLAN_DETAIL,
      param: new DetailRouteParam('plan', planId, '日程详情')
    });
  }

  openTodoDetail(todoId: string): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: AppRoute.TODO_DETAIL,
      param: new DetailRouteParam('todo', todoId, '待办详情')
    });
  }

  openIdeaDetail(ideaId: string): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: AppRoute.IDEA_DETAIL,
      param: new DetailRouteParam('idea', ideaId, '闪记详情')
    });
  }

  back(): void {
    this.pop();
    this.hasOverlayRoute = this.getAllPathName().length > 0;
  }
}
