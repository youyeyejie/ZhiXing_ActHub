/**
 * 数据库配置占位。
 * TODO: 后续整理表名、建表语句版本和迁移计划。
 */
export class DatabaseConfig {
  static readonly DB_NAME: string = 'acthub.db';
  static readonly VERSION: number = 1;
  static readonly PLAN_TABLE: string = 'plans';
  static readonly TODO_TABLE: string = 'todos';
  static readonly TODO_CATEGORY_TABLE: string = 'todo_categories';
  static readonly FOCUS_TABLE: string = 'focus_records';
  static readonly IDEA_TABLE: string = 'ideas';
  static readonly USER_TABLE: string = 'users';
}
