import { Todo } from '../models/Todo';
import { BaseRepository } from './BaseRepository';
import { RepositoryScope } from '../database/RepositoryScope';

/**
 * 组件功能简介：
 * - 待办仓储实现，承载 Todo 实体的数据访问。
 * - 提供按完成状态筛选的能力。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 继承并提供 Todo 实体的基础 CRUD 能力。
 * - 新增 `getUnfinishedTodos` 方法返回未完成待办。
 *
 * 副作用：
 * - 写操作会更新数据库中的 Todo 记录。
 */
export class TodoRepository extends BaseRepository<Todo> {
  constructor() {
    super(Todo, RepositoryScope.USER);
  }

  /**
   * 获取所有未完成的待办任务
   * @returns Promise<Array<Todo>> 未完成待办列表
   */
  getUnfinishedTodos(): Promise<Array<Todo>> {
    const todos: Array<Todo> = this.query
      .where('is_done', 0)
      .orderBy('created_at', 'desc')
      .find();
    return Promise.resolve(todos);
  }
}
