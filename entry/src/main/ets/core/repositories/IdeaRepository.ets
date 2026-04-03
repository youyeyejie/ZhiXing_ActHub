import { DatabaseConfig } from '../database/DatabaseConfig';
import { Idea } from '../models/Idea';
import { BaseRepository } from './BaseRepository';

/**
 * 闪记仓储占位。
 * TODO: 后续补充全文搜索、热力图统计和字数汇总查询。
 */
export class IdeaRepository extends BaseRepository<Idea> {
  constructor() {
    super(DatabaseConfig.IDEA_TABLE, Idea);
  }
}
