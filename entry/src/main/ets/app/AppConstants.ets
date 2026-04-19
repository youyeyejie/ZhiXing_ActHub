/**
 * 组件功能简介：
 * - 应用级常量集合，集中维护应用名、数据库名与偏好存储名。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 通过静态字段提供全局可复用常量。
 *
 * 副作用：
 * - 无。
 */
export class AppConstants {
  static readonly APP_NAME: string = '知行';
  static readonly DATABASE_NAME: string = 'acthub.db';
  static readonly PREFERENCE_NAME: string = 'acthub.preference';
}

/**
 * 组件功能简介：
 * - 偏好键名常量集合，统一管理应用偏好存储键。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 通过静态字段提供偏好键名。
 *
 * 副作用：
 * - 无。
 */
export class AppPreferenceKey {
  static readonly PREFERRED_THEME_MODE: string = 'preferredThemeMode';
  static readonly NOTIFICATION_ENABLED: string = 'notificationEnabled';
  static readonly PLAN_REMINDER_ENABLED: string = 'planReminderEnabled';
}

/**
 * 组件功能简介：
 * - 应用流程枚举，描述启动、认证与主流程阶段。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供流程状态枚举值。
 *
 * 副作用：
 * - 无。
 */
export enum AppFlow {
  SPLASH = 'SPLASH',
  AUTH = 'AUTH',
  MAIN = 'MAIN'
}

/**
 * 组件功能简介：
 * - 主底部标签枚举，定义四个主业务模块入口。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供标签标识枚举值。
 *
 * 副作用：
 * - 无。
 */
export enum AppTab {
  PLAN = 'PLAN',
  TODO = 'TODO',
  IDEA = 'IDEA',
  USER = 'USER'
}

/**
 * 组件功能简介：
 * - 主路由常量集合，定义主页面与专注页面路由名。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供主路由字符串常量。
 *
 * 副作用：
 * - 无。
 */
export class AppRoute {
  static readonly PLAN: string = 'plan';
  static readonly TODO: string = 'todo';
  static readonly IDEA: string = 'idea';
  static readonly USER: string = 'user';
  static readonly FOCUS: string = 'focusPage';
}

/**
 * 组件功能简介：
 * - Overlay 路由常量集合，定义覆盖层目的页路由名。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供 overlay 路由字符串常量。
 *
 * 副作用：
 * - 无。
 */
export class AppOverlayRoute {
  static readonly SEARCH: string = 'search';
  static readonly SHARED_TEST: string = 'sharedTest';
  static readonly ACTION_SHEET: string = 'actionSheet';
  static readonly DETAIL_CARD: string = 'detailCard';
  static readonly AI_INSIGHT: string = 'aiInsight';
}

/**
 * 组件功能简介：
 * - 搜索页路由参数模型，承载模块名与页面标题。
 *
 * 可传入项：
 * - `moduleName`: 当前来源模块名。
 * - `pageTitle`: 搜索页展示标题。
 *
 * 返回行为：
 * - 构造后返回可供路由传递的参数对象。
 *
 * 副作用：
 * - 无。
 */
export class SearchRouteParam {
  moduleName: string;
  pageTitle: string;

  constructor(moduleName: string, pageTitle: string) {
    this.moduleName = moduleName;
    this.pageTitle = pageTitle;
  }
}

/**
 * 组件功能简介：
 * - 专注页路由参数占位模型，为后续扩展字段预留。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回空参数对象实例。
 *
 * 副作用：
 * - 无。
 */
export class FocusRouteParam {
}
