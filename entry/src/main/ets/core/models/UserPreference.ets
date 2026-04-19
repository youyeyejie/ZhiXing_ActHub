import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { BaseEntity } from './BaseEntity';

/**
 * 组件功能简介：
 * - 用户偏好实体模型，按键值对保存当前用户的设置项。
 *
 * 可传入项：
 * - 通过实例字段写入 `key/value/createdAt/updatedAt` 等数据。
 *
 * 返回行为：
 * - 作为 ORM 实体参与用户偏好设置的持久化与查询。
 *
 * 副作用：
 * - 无（数据承载类）。
 */
@Table({ name: 'user_preferences' })
export class UserPreference extends BaseEntity {
  @PrimaryKey()
  id: number = 0;

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  key: string = '';

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  value: string = '';

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
