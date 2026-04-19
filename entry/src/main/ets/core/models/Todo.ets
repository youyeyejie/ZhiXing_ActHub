import { Column, ColumnType, NotNull, PrimaryKey, Table } from "@ibestservices/ibest-orm";
import { DatabaseConfig } from "../database/DatabaseConfig";
import { BaseEntity } from "./BaseEntity";

/**
 * 组件功能简介：
 * - 待办实体模型，对应 `todos` 表，承载待办标题、详情、分类与完成状态。
 *
 * 可传入项：
 * - 通过实例字段写入 `content/detail/categoryId/isDone/inFocus` 等业务数据。
 *
 * 返回行为：
 * - 作为 ORM 实体参与待办模块持久化与查询映射。
 *
 * 副作用：
 * - 无（数据承载类）。
 */
@Table({ name: DatabaseConfig.TODO_TABLE })
export class Todo extends BaseEntity {
  @PrimaryKey()
  id: number = 0;

  @Column({ type: ColumnType.TEXT, notNull: true })
  @NotNull()
  content: string = "";

  @Column({ type: ColumnType.TEXT, notNull: true, defaultValue: "" })
  @NotNull()
  detail: string = "";

  @Column({ type: ColumnType.INTEGER, notNull: true, defaultValue: 0 })
  @NotNull()
  timestamp: number = 0;

  @Column({ name: "category_id", type: ColumnType.INTEGER, defaultValue: 0 })
  categoryId: number = 0;

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
