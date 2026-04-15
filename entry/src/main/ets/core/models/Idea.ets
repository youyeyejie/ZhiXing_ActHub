import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 类功能简介：
 * - 闪记实体模型，对应 `ideas` 表。
 *
 * 可传入项：
 * - 通过实例字段赋值写入标题、正文、长度与时间戳。
 *
 * 返回行为：
 * - 作为 ORM 实体参与闪记数据持久化与查询。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
 */
@ObservedV2
@Table({ name: DatabaseConfig.IDEA_TABLE })
export class Idea extends BaseEntity {
  @PrimaryKey()
  @Trace id: number = 0;

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  @Trace title: string = '';

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  @Trace content: string = '';

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace length: number = 0;

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace timestamp: number = 0;

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace updatedAt: number = 0;
}
