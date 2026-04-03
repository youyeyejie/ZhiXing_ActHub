import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 日程实体定义。
 * 对齐详细设计中的 plans 表，并为提醒、循环和课程模式预留字段。
 */
@Table({ name: DatabaseConfig.PLAN_TABLE })
export class Plan extends BaseEntity {
  @PrimaryKey()
  id: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  content: string = '';

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

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  location: string = '';

  @Column({ name: 'is_course', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  isCourse: number = 0;

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  description: string = '';

  @Column({ name: 'loop_rule', type: ColumnType.TEXT, defaultValue: '' })
  loopRule: string = '';

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
