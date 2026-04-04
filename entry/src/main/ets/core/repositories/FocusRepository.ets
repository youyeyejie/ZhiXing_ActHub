import { DatabaseConfig } from '../database/DatabaseConfig';
import { Focus } from '../models/Focus';
import { BaseRepository } from './BaseRepository';

/**
 * 专注仓储占位。
 * TODO: 后续补充按日期聚合、按待办统计和时长报表查询。
 */
export class FocusRepository extends BaseRepository<Focus> {
  constructor() {
    super(DatabaseConfig.FOCUS_TABLE, Focus);
  }
}
