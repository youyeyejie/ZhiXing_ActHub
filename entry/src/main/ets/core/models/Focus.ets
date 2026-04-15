import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 类功能简介：
 * - 专注记录实体模型，对应 `focus_records` 表。
 *
 * 可传入项：
 * - 通过实例字段赋值写入待办关联、时长与起止时间信息。
 *
 * 返回行为：
 * - 作为 ORM 实体参与专注记录持久化与查询。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
 */
@Table({ name: DatabaseConfig.FOCUS_TABLE })
export class Focus extends BaseEntity {
  @PrimaryKey()
  id: number = 0;

  @Column({ name: 'todo_id', type: ColumnType.INTEGER, defaultValue: 0 })
  todoId: number = 0;

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  timestamp: number = 0;

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  duration: number = 0;

  @Column({ name: 'start_time', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  startTime: number = 0;

  @Column({ name: 'end_time', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  endTime: number = 0;

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
