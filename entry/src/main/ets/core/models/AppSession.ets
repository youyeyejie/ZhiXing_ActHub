import { Column, ColumnType, NotNull, PrimaryKey, Table } from '@ibestservices/ibest-orm';
@Table({ name: 'app_sessions' })
export class AppSession {
  @PrimaryKey({ autoIncrement: false })
  id: string = 'current';

  @Column({ name: 'user_id', type: ColumnType.TEXT, defaultValue: '' })
  userId: string = '';

  @Column({ name: 'username', type: ColumnType.TEXT, defaultValue: '' })
  username: string = '';

  @Column({ name: 'is_logged_in', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  isLoggedIn: number = 0;

  @Column({ name: 'updated_at', type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
