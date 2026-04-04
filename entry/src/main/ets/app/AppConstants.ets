/**
 * 应用级常量。
 * TODO: 后续统一维护路由名、数据库名、通知通道等全局常量。
 */
export class AppConstants {
  static readonly APP_NAME: string = 'ZhiXing ActHub';
  static readonly DATABASE_NAME: string = 'acthub.db';
  static readonly PREFERENCE_NAME: string = 'acthub.preference';
}

export enum AppTab {
  PLAN = 'PLAN',
  TODO = 'TODO',
  FOCUS = 'FOCUS',
  IDEA = 'IDEA',
  USER = 'USER',
  TEST = 'TEST'
}
