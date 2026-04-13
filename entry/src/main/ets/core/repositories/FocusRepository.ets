import { Focus } from '../models/Focus';
import { BaseRepository } from './BaseRepository';

/**
 * 类功能简介：
 * - 专注仓储实现，承载 Focus 实体的数据访问。
 * - TODO: 尚未补充按日期与待办维度聚合报表。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 继承并提供 Focus 实体的基础 CRUD 能力。
 *
 * 副作用：
 * - 写操作会更新数据库中的 Focus 记录。
 */
export class FocusRepository extends BaseRepository<Focus> {
  constructor() {
    super(Focus);
  }

  /**
   * 插入专注记录（带有异常处理）
   * @param focus 专注记录实体
   * @returns 插入成功返回true，失败返回false
   */
  async insertFocusRecord(focus: Focus): Promise<boolean> {
    try {
      await this.save(focus);
      console.log(`[focusRepository]专注记录已保存: ${focus.id}, 时长: ${focus.duration}秒, 专注对应的todoID ${focus.todoId}`);
      return true;
    } catch (error) {
      console.error('插入专注记录失败:', error);
      return false;
    }
  }
}
