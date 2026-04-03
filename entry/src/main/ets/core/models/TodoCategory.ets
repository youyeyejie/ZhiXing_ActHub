import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 待办分类实体定义。
 * 对齐详细设计中的 todo_categories 表。
 */
@Table({ name: DatabaseConfig.TODO_CATEGORY_TABLE })
export class TodoCategory extends BaseEntity {
  @PrimaryKey()
  id: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  category: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  color: string = '';

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
