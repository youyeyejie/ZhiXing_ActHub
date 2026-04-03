import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 待办实体定义。
 * 对齐详细设计中的 todos 表，当前仅保留分类与专注记录所需外键字段。
 */
@Table({ name: DatabaseConfig.TODO_TABLE })
export class Todo extends BaseEntity {
  @PrimaryKey()
  id: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  content: string = '';

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  timestamp: number = 0;

  @Column({ name: 'category_id', type: ColumnType.TEXT, defaultValue: '' })
  categoryId: string = '';

  @Column({ name: 'is_done', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  isDone: number = 0;

  @Column({ name: 'in_focus', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  inFocus: number = 0;

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
