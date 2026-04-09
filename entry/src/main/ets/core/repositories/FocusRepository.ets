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
}
