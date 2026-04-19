import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';

/**
 * 组件功能简介：
 * - 应用会话实体模型，保存当前登录会话状态与用户名。
 *
 * 可传入项：
 * - 通过实例字段写入 `id/userId/username/isLoggedIn/updatedAt`。
 *
 * 返回行为：
 * - 作为 ORM 实体参与会话状态持久化与读取。
 *
 * 副作用：
 * - 无（数据承载类）。
 */
@Table({ name: 'app_sessions' })
export class AppSession {
  @PrimaryKey({ autoIncrement: false })
  id: string = 'current';

  @Column({ name: 'user_id', type: ColumnType.TEXT, defaultValue: '' })
  userId: string = '';

  @Column({ name: 'username', type: ColumnType.TEXT, defaultValue: '' })
  username: string = '';

  @Column({ name: 'is_logged_in', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  isLoggedIn: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
