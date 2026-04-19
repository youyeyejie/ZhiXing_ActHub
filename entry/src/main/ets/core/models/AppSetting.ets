import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from '../database/DatabaseConfig';

/**
 * 组件功能简介：
 * - 应用级设置实体模型，用于保存跨用户共享的应用设置键值。
 *
 * 可传入项：
 * - 通过实例字段写入 `key/value/updatedAt`。
 *
 * 返回行为：
 * - 作为 ORM 实体参与 AppSetting 持久化与查询。
 *
 * 副作用：
 * - 无（数据承载类）。
 */
@Table({ name: DatabaseConfig.APP_SETTING_TABLE })
export class AppSetting {
  @PrimaryKey()
  id: number = 0;

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  key: string = '';

  @Column({ type: ColumnType.TEXT, defaultValue: '' })
  value: string = '';

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
