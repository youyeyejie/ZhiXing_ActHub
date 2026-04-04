import { DatabaseConfig } from '../database/DatabaseConfig';
import { Todo } from '../models/Todo';
import { BaseRepository } from './BaseRepository';

/**
 * 待办仓储占位。
 * TODO: 后续补充按分类、完成状态和专注绑定条件查询。
 */
export class TodoRepository extends BaseRepository<Todo> {
  constructor() {
    super(DatabaseConfig.TODO_TABLE);
  }
}
