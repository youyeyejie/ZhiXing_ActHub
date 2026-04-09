import { Idea } from '../models/Idea';
import { BaseRepository } from './BaseRepository';

/**
 * 类功能简介：
 * - 闪记仓储实现，承载 Idea 实体的数据访问。
 * - TODO: 尚未补充全文搜索与统计查询。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 继承并提供 Idea 实体的基础 CRUD 能力。
 *
 * 副作用：
 * - 写操作会更新数据库中的 Idea 记录。
 */
export class IdeaRepository extends BaseRepository<Idea> {
  constructor() {
    super(Idea);
  }
}
