import { Todo } from '../models/Todo';
import { TodoRepository } from '../repositories/TodoRepository';

/**
 * 组件功能简介：
 * - 运行时测试数据助手，用于批量生成专注场景待办样本。
 *
 * 可传入项：
 * - `generateFocusTestData(count)` 的 `count` 为生成条数。
 *
 * 返回行为：
 * - 返回实际成功插入的数据条数。
 *
 * 副作用：
 * - 会写入用户数据库中的待办记录。
 */
export class TodoTestDataHelper {
  private repository: TodoRepository = new TodoRepository();

  async generateFocusTestData(count: number = 8): Promise<number> {
    const now = Date.now();
    const oneDayMs: number = 24 * 60 * 60 * 1000;
    let insertedCount: number = 0;

    for (let i = 0; i < count; i++) {
      const todo = new Todo();
      const seq = i + 1;
      const isDone = seq % 4 === 0 ? 1 : 0;
      const createdAt = now - seq * oneDayMs;
      todo.content = `专注测试待办 #${seq}`;
      todo.detail = isDone === 1 ? '已完成样本（用于过滤验证）' : '未完成样本（应出现在任务选择器）';
      todo.timestamp = createdAt;
      todo.categoryId = 0;
      todo.isDone = isDone;
      todo.inFocus = 0;
      todo.createdAt = createdAt;
      todo.updatedAt = createdAt;

      try {
        await this.repository.save(todo);
        insertedCount = insertedCount + 1;
      } catch (_error) {
      }
    }

    return insertedCount;
  }
}
