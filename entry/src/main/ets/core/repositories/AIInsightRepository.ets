import { ORM } from '@ibestservices/ibest-orm';
import { AIInsight } from '../models/AIInsight';
import { UserDatabase } from '../database/UserDatabase';

/**
 * AI 洞察历史仓储。
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
