import { AppRoute, AppTab, FocusRouteParam, SearchRouteParam } from './AppConstants';

/**
 * 应用主导航状态。
 * 基于 Navigation 控制器扩展应用级导航能力。
 * 当前 MVP 阶段负责维护主标签页状态，并为后续搜索、详情和专注页提供统一入口。
 */
@ObservedV2
export class AppNav extends NavPathStack {
  @Trace public mainRouteName: string = AppRoute.PLAN;
  @Trace public hasOverlayRoute: boolean = false;
  @Trace public detailModuleName: string = '';
  @Trace public detailRecordId: string = '';

  selectTab(tab: AppTab): void {
    this.navigateByName(this.resolveMainRouteByTab(tab));
  }

  /**
   * 按名称切换应用一级页面。
   * 这里只接受四个主页面和专注页，其它覆盖页应走 pushOverlayByName。
   */
  navigateByName(routeName: string): boolean {
    if (routeName === AppRoute.FOCUS) {
      this.openFocus();
      return true;
    }
    if (routeName === AppRoute.PLAN ||
      routeName === AppRoute.TODO ||
      routeName === AppRoute.IDEA ||
      routeName === AppRoute.USER) {
      this.mainRouteName = routeName;
      return true;
    }
    return false;
  }

  /**
   * 向导航栈压入覆盖页。
   * 用于搜索页、测试页等叠加式目的页，不改变当前主页面选中状态。
   */
  pushOverlayByName(routeName: string, param: Object | undefined = undefined, animated: boolean = true): void {
    this.pushOverlayRoute(routeName, param, animated);
  }

  openFocus(): void {
    this.pushOverlayRoute(AppRoute.FOCUS, new FocusRouteParam(), false);
  }

  back(animated: boolean = true): void {
    const pathNames = this.getAllPathName();
    const remainingCount = pathNames.length > 0 ? pathNames.length - 1 : 0;
    this.hasOverlayRoute = remainingCount > 0;
    if (remainingCount === 0) {
      this.clearDetailState();
    }
    this.pop(animated);
  }

  currentTab(): AppTab {
    if (this.mainRouteName === AppRoute.TODO) {
      return AppTab.TODO;
    }
    if (this.mainRouteName === AppRoute.IDEA) {
      return AppTab.IDEA;
    }
    if (this.mainRouteName === AppRoute.USER) {
      return AppTab.USER;
    }
    return AppTab.PLAN;
  }

  /**
   * 创建搜索覆盖页参数。
   * 搜索页本身只有一个 route name，具体模块和标题通过参数区分。
   */
  createSearchParam(moduleName: string, pageTitle: string): SearchRouteParam {
    return new SearchRouteParam(moduleName, pageTitle);
  }

  private resolveMainRouteByTab(tab: AppTab): string {
    if (tab === AppTab.TODO) {
      return AppRoute.TODO;
    }
    if (tab === AppTab.IDEA) {
      return AppRoute.IDEA;
    }
    if (tab === AppTab.USER) {
      return AppRoute.USER;
    }
    return AppRoute.PLAN;
  }

  private pushOverlayRoute(routeName: string, param: Object | undefined, animated: boolean): void {
    this.hasOverlayRoute = true;
    this.pushPath({
      name: routeName,
      param: param,
      onPop: (_info: PopInfo): void => {
        this.syncOverlayState();
      }
    }, animated);
  }

  private syncOverlayState(): void {
    const pathNames = this.getAllPathName();
    this.hasOverlayRoute = pathNames.length > 0;
    if (pathNames.length === 0) {
      this.clearDetailState();
    }
  }

  private clearDetailState(): void {
    this.detailModuleName = '';
    this.detailRecordId = '';
  }
}
