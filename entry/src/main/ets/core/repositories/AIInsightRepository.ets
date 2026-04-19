import { ORM } from '@ibestservices/ibest-orm';
import { AIInsight } from '../models/AIInsight';
import { UserDatabase } from '../database/UserDatabase';

/**
 * 组件功能简介：
 * - AI 洞察历史仓储，负责洞察记录的增删查。
 *
 * 可传入项：
 * - `save(record)` 传入待保存的洞察记录。
 * - `removeById(id)` 传入目标记录主键。
 *
 * 返回行为：
 * - 提供洞察记录保存、按时间倒序查询与删除能力。
 *
 * 副作用：
 * - 会直接写入或删除用户数据库中的 `ai_insights` 记录。
 */
export class AIInsightRepository {
  private get orm(): ORM {
    return UserDatabase.getInstance().getOrm();
  }

  save(record: AIInsight): Promise<void> {
    const id: number = record.id;
    if (id <= 0) {
      this.orm.insert<AIInsight>(record);
      return Promise.resolve();
    }

    const existed: AIInsight | null = this.orm.query(AIInsight).where('id', id).first();
    if (existed === null) {
      this.orm.insert<AIInsight>(record);
    } else {
      this.orm.save<AIInsight>(record);
    }
    return Promise.resolve();
  }

  findLatest(): Promise<Array<AIInsight>> {
    const records: Array<AIInsight> = this.orm
      .query(AIInsight)
      .orderBy('created_at', 'desc')
      .find();
    return Promise.resolve(records);
  }

  removeById(id: number): Promise<void> {
    const record: AIInsight | null = this.orm.query(AIInsight).where('id', id).first();
    if (record !== null) {
      this.orm.delete(record);
    }
    return Promise.resolve();
  }
}
