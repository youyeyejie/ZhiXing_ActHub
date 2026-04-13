import { Column, ColumnType, NotNull, PrimaryKey, Table } from "@ibestservices/ibest-orm";
import { DatabaseConfig } from "../database/DatabaseConfig";
import { BaseEntity } from "./BaseEntity";

/**
 * 待办实体定义。
 * 对齐待办模块 MVP 所需字段：标题（content）+ 详情（detail）+ 分类/状态信息。
 */
@Table({ name: DatabaseConfig.TODO_TABLE })
export class Todo extends BaseEntity {
  @PrimaryKey()
  id: string = "";

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  content: string = "";

  @Column({ type: ColumnType.TEXT, notNull: true, defaultValue: "" })
  @NotNull()
  detail: string = "";

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  timestamp: number = 0;

  @Column({ name: "category_id", type: ColumnType.TEXT, defaultValue: "" })
  categoryId: string = "";

  @Column({ name: "is_done", type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  isDone: number = 0;

  @Column({ name: "in_focus", type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  inFocus: number = 0;

  @Column({ name: "created_at", type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  createdAt: number = 0;

  @Column({ name: "updated_at", type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  updatedAt: number = 0;
}
