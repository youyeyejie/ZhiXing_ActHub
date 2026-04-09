import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 类功能简介：
 * - 待办实体模型，对应 `todos` 表。
 *
 * 可传入项：
 * - 通过实例字段赋值写入内容、分类、完成态与专注关联状态。
 *
 * 返回行为：
 * - 作为 ORM 实体参与持久化读写与查询映射。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
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
