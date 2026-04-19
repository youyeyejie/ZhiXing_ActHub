import { AppOverlayRoute, AppRoute, AppTab, FocusRouteParam, SearchRouteParam } from './AppConstants';

/**
 * 组件功能简介：
 * - 应用主导航状态管理器，封装主页面切换与 overlay 路由操作。
 *
 * 可传入项：
 * - 公开方法可接收标签枚举、路由名、覆盖页参数与内容 Builder。
 *
 * 返回行为：
 * - 提供主路由状态、当前标签、覆盖页开关与导航操作能力。
 *
 * 副作用：
 * - 会修改导航栈与响应式路由状态字段。
 */
@ObservedV2
export class AppNav extends NavPathStack {
  private static readonly DEFAULT_ACTION_SHEET_HEIGHT: string = '56%';
  private static readonly DEFAULT_DETAIL_CARD_HEIGHT: string = '60%';
  @Trace public mainRouteName: string = AppRoute.PLAN;
  @Trace public hasOverlayRoute: boolean = false;
  @Trace public detailModuleName: string = '';
  @Trace public detailRecordId: number = 0;
  public actionSheetContentBuilder: () => void = () => {};
  public detailCardContentBuilder: () => void = () => {};
  public actionSheetHeight: string = AppNav.DEFAULT_ACTION_SHEET_HEIGHT;
  public detailCardHeight: string = AppNav.DEFAULT_DETAIL_CARD_HEIGHT;

  /**
   * 按标签切换主页面。
   */
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

  /**
   * 打开专注覆盖页。
   */
  openFocus(): void {
    this.pushOverlayRoute(AppRoute.FOCUS, new FocusRouteParam(), false);
  }

  /**
   * 打开 ActionSheet 覆盖页。
   */
  openActionSheet(contentBuilder: () => void = () => {}, height: string = AppNav.DEFAULT_ACTION_SHEET_HEIGHT): void {
    this.actionSheetContentBuilder = contentBuilder;
    this.actionSheetHeight = this.resolveOverlayHeight(height, AppNav.DEFAULT_ACTION_SHEET_HEIGHT);
    // 禁用路由级动画，仅保留 ActionSheet 组件内部动画，避免遮罩随路由整体滑动。
    this.pushOverlayRoute(AppOverlayRoute.ACTION_SHEET, undefined, false);
  }

  /**
   * 打开 DetailCard 覆盖页。
   */
  openDetailCard(contentBuilder: () => void = () => {}, height: string = AppNav.DEFAULT_DETAIL_CARD_HEIGHT): void {
    this.detailCardContentBuilder = contentBuilder;
    this.detailCardHeight = this.resolveOverlayHeight(height, AppNav.DEFAULT_DETAIL_CARD_HEIGHT);
    this.pushOverlayRoute(AppOverlayRoute.DETAIL_CARD, undefined, false);
  }

  /**
   * 返回上一级路由并同步覆盖页状态。
   */
  back(animated: boolean = true): void {
    const pathNames = this.getAllPathName();
    const remainingCount = pathNames.length > 0 ? pathNames.length - 1 : 0;
    this.hasOverlayRoute = remainingCount > 0;
    if (remainingCount === 0) {
      this.clearDetailState();
    }
    this.pop(animated);
  }

  /**
   * 根据当前主路由反查选中标签。
   */
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

  /**
   * 将标签枚举映射到主路由名。
   */
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

  /**
   * 统一压入覆盖页并附带 onPop 同步逻辑。
   */
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

  /**
   * 根据栈状态刷新 hasOverlayRoute。
   */
  private syncOverlayState(): void {
    const pathNames = this.getAllPathName();
    this.hasOverlayRoute = pathNames.length > 0;
    if (pathNames.length === 0) {
      this.clearDetailState();
    }
  }

  /**
   * 兜底覆盖页高度，空字符串时回退默认值。
   */
  private resolveOverlayHeight(height: string, fallback: string): string {
    const normalized = `${height}`.trim();
    if (normalized.length === 0) {
      return fallback;
    }
    return normalized;
  }

  /**
   * 清理覆盖页内容 builder 与详情状态。
   */
  private clearDetailState(): void {
    this.detailModuleName = '';
    this.detailRecordId = 0;
    this.actionSheetHeight = AppNav.DEFAULT_ACTION_SHEET_HEIGHT;
    this.detailCardHeight = AppNav.DEFAULT_DETAIL_CARD_HEIGHT;
    this.actionSheetContentBuilder = () => {};
    this.detailCardContentBuilder = () => {};
  }
}
