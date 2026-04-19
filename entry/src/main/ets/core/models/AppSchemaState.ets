import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';

/**
 * 组件功能简介：
 * - 应用 Schema 状态实体，记录数据库迁移版本信息。
 *
 * 可传入项：
 * - 通过实例字段写入 `schemaVersion/updatedAt`。
 *
 * 返回行为：
 * - 作为 ORM 实体用于数据库版本追踪。
 *
 * 副作用：
 * - 无（数据承载类）。
 */
@Table({ name: 'app_schema_state' })
export class AppSchemaState {
  @PrimaryKey({ autoIncrement: false })
  id: string = 'app';

  @Column({ name: 'schema_version', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  schemaVersion: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
