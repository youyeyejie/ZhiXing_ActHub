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
  static readonly FOCUS: string = 'focusPage';
  static readonly PLAN_SEARCH: string = 'planSearch';
  static readonly TODO_SEARCH: string = 'todoSearch';
  static readonly IDEA_SEARCH: string = 'ideaSearch';
  static readonly PLAN_DETAIL: string = 'planDetail';
  static readonly TODO_DETAIL: string = 'todoDetail';
  static readonly IDEA_DETAIL: string = 'ideaDetail';
  static readonly USER_SETTINGS: string = 'userSettings';
  static readonly SHARED_TEST: string = 'sharedTest';
}

export class SearchRouteParam {
  moduleName: string;
  pageTitle: string;

  constructor(moduleName: string, pageTitle: string) {
    this.moduleName = moduleName;
    this.pageTitle = pageTitle;
  }
}

export class DetailRouteParam {
  moduleName: string;
  recordId: string;
  pageTitle: string;

  constructor(moduleName: string, recordId: string, pageTitle: string) {
    this.moduleName = moduleName;
    this.recordId = recordId;
    this.pageTitle = pageTitle;
  }
}
