/**
 * 应用级常量。
 * TODO: 后续统一维护路由名、数据库名、通知通道等全局常量。
 */
export class AppConstants {
  static readonly APP_NAME: string = 'ZhiXing ActHub';
  static readonly DATABASE_NAME: string = 'acthub.db';
  static readonly PREFERENCE_NAME: string = 'acthub.preference';
}

export enum AppFlow {
  SPLASH = 'SPLASH',
  AUTH = 'AUTH',
  MAIN = 'MAIN'
}

export enum AppTab {
  PLAN = 'PLAN',
  TODO = 'TODO',
  IDEA = 'IDEA',
  USER = 'USER'
}

export class AppRoute {
  /**
   * 应用主页面路由名。
   * 这些路由由应用壳层直接分发，属于代码内显式支持的基础页面跳转：
   * 四个主标签页，以及从底部中间入口进入的专注页。
   */
  static readonly PLAN: string = 'plan';
  static readonly TODO: string = 'todo';
  static readonly IDEA: string = 'idea';
  static readonly USER: string = 'user';
  static readonly FOCUS: string = 'focusPage';
}

/**
 * 栈内覆盖页路由名。
 * 当前仅作为单页内动态元素的命名规范，
 * 用于搜索页、共享测试页等“叠加在主页面之上”的目的页；
 * 这类页面保留动态 push/pop 能力，但不作为应用主导航中的直接跳转目标。
 */
export class AppOverlayRoute {
  static readonly SEARCH: string = 'search';
  static readonly SHARED_TEST: string = 'sharedTest';
  static readonly ACTION_SHEET: string = 'actionSheet';
  static readonly DETAIL_CARD: string = 'detailCard';
}

export class SearchRouteParam {
  moduleName: string;
  pageTitle: string;

  constructor(moduleName: string, pageTitle: string) {
    this.moduleName = moduleName;
    this.pageTitle = pageTitle;
  }
}

export class FocusRouteParam {
}
