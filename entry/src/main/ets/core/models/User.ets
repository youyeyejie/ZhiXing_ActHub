import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 用户实体定义。
 * 对齐详细设计中的 users 表，当前仅覆盖本地登录注册所需最小字段。
 */
@Table({ name: DatabaseConfig.USER_TABLE })
export class User extends BaseEntity {
  @PrimaryKey()
  id: string = '';

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
