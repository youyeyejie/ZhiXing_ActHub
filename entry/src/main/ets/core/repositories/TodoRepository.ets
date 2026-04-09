import { Todo } from '../models/Todo';
import { BaseRepository } from './BaseRepository';

/**
 * 类功能简介：
 * - 待办仓储实现，承载 Todo 实体的数据访问。
 * - TODO: 尚未补充分组筛选与专注绑定查询。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 继承并提供 Todo 实体的基础 CRUD 能力。
 *
 * 副作用：
 * - 写操作会更新数据库中的 Todo 记录。
 */
export class TodoRepository extends BaseRepository<Todo> {
  constructor() {
    super(Todo);
  }
}
