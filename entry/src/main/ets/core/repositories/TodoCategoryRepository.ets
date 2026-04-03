import { DatabaseConfig } from '../database/DatabaseConfig';
import { TodoCategory } from '../models/TodoCategory';
import { BaseRepository } from './BaseRepository';

/**
 * 待办分类仓储占位。
 * TODO: 后续补充分类排序、颜色筛选和默认分类初始化。
 */
export class TodoCategoryRepository extends BaseRepository<TodoCategory> {
  constructor() {
    super(DatabaseConfig.TODO_CATEGORY_TABLE, TodoCategory);
  }
}
