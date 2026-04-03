import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 闪记实体定义。
 * 对齐详细设计中的 ideas 表。
 */
@Table({ name: DatabaseConfig.IDEA_TABLE })
export class Idea extends BaseEntity {
  @PrimaryKey()
  id: string = '';

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  title: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  content: string = '';

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  length: number = 0;

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
