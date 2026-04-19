import { Plan } from '../models/Plan';
import { BaseRepository } from './BaseRepository';
import { RepositoryScope } from '../database/RepositoryScope';

/**
 * 组件功能简介：
 * - 日程仓储实现，承载 Plan 实体的数据访问。
 * - TODO: 尚未补充日期范围与类型维度查询能力。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 继承并提供 Plan 实体的基础 CRUD 能力。
 *
 * 副作用：
 * - 写操作会更新数据库中的 Plan 记录。
 */
export class PlanRepository extends BaseRepository<Plan> {
  constructor() {
    super(Plan, RepositoryScope.USER);
  }
}
