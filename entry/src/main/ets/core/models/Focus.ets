import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 专注记录实体定义。
 * 对齐详细设计中的专注记录表，并保留与待办绑定所需外键字段。
 */
@Table({ name: DatabaseConfig.FOCUS_TABLE })
export class Focus extends BaseEntity {
  @PrimaryKey()
  id: string = '';

  @Column({ name: 'todo_id', type: ColumnType.TEXT, defaultValue: '' })
  todoId: string = '';

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
