/**
 * 类功能简介：
 * - 应用级静态常量集合。
 * - TODO: 后续补充通知通道、键名与全局配置常量。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供可复用常量值。
 *
 * 副作用：
 * - 无副作用。
 */
export class AppConstants {
  static readonly APP_NAME: string = 'ZhiXing ActHub';
  static readonly DATABASE_NAME: string = 'acthub.db';
  static readonly PREFERENCE_NAME: string = 'acthub.preference';
}

/**
 * 类型功能简介：
 * - 应用流程状态枚举（启动/认证/主流程）。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 为流程分发逻辑提供状态值约束。
 *
 * 副作用：
 * - 无副作用。
 */
export enum AppFlow {
  SPLASH = 'SPLASH',
  AUTH = 'AUTH',
  MAIN = 'MAIN'
}

/**
 * 类型功能简介：
 * - 主标签页枚举类型。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 为主页面切换提供标签值约束。
 *
 * 副作用：
 * - 无副作用。
 */
export enum AppTab {
  PLAN = 'PLAN',
  TODO = 'TODO',
  IDEA = 'IDEA',
  USER = 'USER'
}

/**
 * 类功能简介：
 * - 应用主页面路由常量集合。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供主页面路由名常量。
 *
 * 副作用：
 * - 无副作用。
 */
export class AppRoute {
  static readonly PLAN: string = 'plan';
  static readonly TODO: string = 'todo';
  static readonly IDEA: string = 'idea';
  static readonly USER: string = 'user';
  static readonly FOCUS: string = 'focusPage';
}

/**
 * 类功能简介：
 * - 覆盖页路由常量集合，定义 overlay 目的页命名。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供 overlay 路由名常量。
 *
 * 副作用：
 * - 无副作用。
 */
export class AppOverlayRoute {
  static readonly SEARCH: string = 'search';
  static readonly SHARED_TEST: string = 'sharedTest';
  static readonly ACTION_SHEET: string = 'actionSheet';
  static readonly DETAIL_CARD: string = 'detailCard';
}

/**
 * 类功能简介：
 * - 搜索页路由参数对象。
 *
 * 可传入项：
 * - 构造参数 `moduleName` 与 `pageTitle`。
 *
 * 返回行为：
 * - 构造后返回可直接传给搜索 overlay 的参数对象。
 *
 * 副作用：
 * - 无副作用。
 */
export class SearchRouteParam {
  moduleName: string;
  pageTitle: string;

  /**
  * @param moduleName 搜索来源模块名
  * @param pageTitle 搜索页标题
   */
  constructor(moduleName: string, pageTitle: string) {
    this.moduleName = moduleName;
    this.pageTitle = pageTitle;
  }
}

/**
 * 类功能简介：
 * - 专注页路由参数占位对象。
 * - TODO: 尚未补充来源场景、默认时长和关联待办 ID。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 作为专注页路由参数占位类型。
 *
 * 副作用：
 * - 无副作用。
 */
export class FocusRouteParam {
}
