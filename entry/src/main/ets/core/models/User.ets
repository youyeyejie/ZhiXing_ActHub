import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 组件功能简介：
 * - 用户实体模型，对应 `users` 表。
 *
 * 可传入项：
 * - 通过实例字段赋值写入账号、头像、密码与时间戳字段。
 *
 * 返回行为：
 * - 作为 ORM 实体参与本地用户数据持久化与查询。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
 */
@Table({ name: DatabaseConfig.USER_TABLE })
export class User extends BaseEntity {
  @PrimaryKey()
  id: number = 0;

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  name: string = '';

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  avatar: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  password: string = '';

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  timestamp: number = 0;

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
