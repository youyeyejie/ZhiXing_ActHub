import { TodoCategory } from '../models/TodoCategory';
import { BaseRepository } from './BaseRepository';

/**
 * 类功能简介：
 * - 待办分类仓储实现，承载 TodoCategory 实体的数据访问。
 * - TODO: 尚未补充排序、默认分类初始化和颜色筛选。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 继承并提供 TodoCategory 实体的基础 CRUD 能力。
 *
 * 副作用：
 * - 写操作会更新数据库中的分类记录。
 */
export class TodoCategoryRepository extends BaseRepository<TodoCategory> {
  constructor() {
    super(TodoCategory);
  }
}
