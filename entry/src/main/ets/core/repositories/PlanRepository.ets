import { DatabaseConfig } from '../database/DatabaseConfig';
import { Plan } from '../models/Plan';
import { BaseRepository } from './BaseRepository';

/**
 * 日程仓储占位。
 * TODO: 后续补充按日期范围、按课程类型和提醒时间查询能力。
 */
export class PlanRepository extends BaseRepository<Plan> {
  constructor() {
    super(DatabaseConfig.PLAN_TABLE, Plan);
  }
}
