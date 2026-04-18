/**
 * 类功能简介：
 * - 数据库常量配置类，集中维护数据库名、版本与表名。
 * - TODO: 后续补充迁移策略与版本管理规范。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 对外提供静态常量供数据库与模型层引用。
 *
 * 副作用：
 * - 无副作用。
 */
export class DatabaseConfig {
  static readonly DB_NAME: string = 'acthub.db';
  static readonly VERSION: number = 2;
  static readonly PLAN_TABLE: string = 'plans';
  static readonly TODO_TABLE: string = 'todos';
  static readonly TODO_CATEGORY_TABLE: string = 'todo_categories';
  static readonly FOCUS_TABLE: string = 'focus_records';
  static readonly IDEA_TABLE: string = 'ideas';
  static readonly AI_INSIGHT_TABLE: string = 'ai_insights';
  static readonly USER_TABLE: string = 'users';
  static readonly APP_SESSION_TABLE: string = 'app_sessions';
  static readonly APP_SCHEMA_STATE_TABLE: string = 'app_schema_state';
  static readonly APP_SETTING_TABLE: string = 'app_settings';
}
