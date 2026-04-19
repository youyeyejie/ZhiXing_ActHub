import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';
import { BaseEntity } from './BaseEntity';

/**
 * 组件功能简介：
 * - AI 洞察历史实体模型，对应 `ai_insights` 表。
 *
 * 可传入项：
 * - 通过实例字段写入 `mode/keywords/summary/fullContent/noteCount/totalLength` 等数据。
 *
 * 返回行为：
 * - 作为 ORM 实体参与 AI 洞察历史记录持久化与读取。
 *
 * 副作用：
 * - 无（数据承载类）。
 */
@ObservedV2
@Table({ name: DatabaseConfig.AI_INSIGHT_TABLE })
export class AIInsight extends BaseEntity {
  @PrimaryKey()
  @Trace id: number = 0;

  @Column({ type: ColumnType.TEXT, notNull: true, defaultValue: 'global' })
  @NotNull()
  @Trace mode: string = 'global';

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  @Trace keywords: string = '';

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  @Trace summary: string = '';

  @Column({ name: 'full_content', type: ColumnType.TEXT, notNull: true, defaultValue: '' })
  @NotNull()
  @Trace fullContent: string = '';

  @Column({ name: 'note_count', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace noteCount: number = 0;

  @Column({ name: 'total_length', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace totalLength: number = 0;

  @Column({ name: 'created_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace createdAt: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  @Trace updatedAt: number = 0;
}