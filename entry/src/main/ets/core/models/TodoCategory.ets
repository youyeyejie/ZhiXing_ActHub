import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 类功能简介：
 * - 待办分类实体模型，对应 `todo_categories` 表。
 *
 * 可传入项：
 * - 通过实例字段赋值写入分类名称与颜色值。
 *
 * 返回行为：
 * - 作为 ORM 实体参与分类数据持久化与查询。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
 */
@Table({ name: DatabaseConfig.TODO_CATEGORY_TABLE })
export class TodoCategory extends BaseEntity {
  @PrimaryKey()
  id: number = 0;

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
