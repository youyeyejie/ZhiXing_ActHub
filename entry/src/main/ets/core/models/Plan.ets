import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 类功能简介：
 * - 日程实体模型，对应 `plans` 表。
 *
 * 可传入项：
 * - 通过实例字段赋值写入日程内容、时间、地点与描述。
 *
 * 返回行为：
 * - 作为 ORM 实体参与持久化读写与查询映射。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
 */
@Table({ name: DatabaseConfig.PLAN_TABLE })
export class Plan extends BaseEntity {
  @PrimaryKey()
  id: number = 0;

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

  @Column({ name: 'reminder_id', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  // 外部提醒记录 ID；当前实现中复用为系统日历 eventId。
  reminderId: number = 0;

  @Column({ name: 'enable_remind', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  enableRemind: number = 0;

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
