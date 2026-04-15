import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
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
