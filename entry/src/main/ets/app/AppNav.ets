import { AppRoute, AppTab, DetailRouteParam, FocusRouteParam, SearchRouteParam } from './AppConstants';

/**
 * 应用主导航状态。
 * 基于 Navigation 控制器扩展应用级导航能力。
 * 当前 MVP 阶段负责维护主标签页状态，并为后续搜索、详情和专注页提供统一入口。
 */
@ObservedV2
export class AppNav extends NavPathStack {
  @Trace public selectedTab: AppTab = AppTab.PLAN;
  @Trace public hasOverlayRoute: boolean = false;
  @Trace public detailModuleName: string = '';
  @Trace public detailRecordId: string = '';

  selectTab(tab: AppTab): void {
    this.selectedTab = tab;
  }

  openFocus(): void {
    this.hasOverlayRoute = true;
    this.pushPathByName(AppRoute.FOCUS, new FocusRouteParam(), false);
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

  openSharedTest(): void {
    this.hasOverlayRoute = true;
    this.pushPath({ name: AppRoute.SHARED_TEST });
  }

  back(animated: boolean = true): void {
    this.pop(animated);
    const pathNames = this.getAllPathName();
    this.hasOverlayRoute = pathNames.length > 0;
    if (pathNames.length === 0 ) {
      this.detailModuleName = '';
      this.detailRecordId = '';
    }
  }
}
