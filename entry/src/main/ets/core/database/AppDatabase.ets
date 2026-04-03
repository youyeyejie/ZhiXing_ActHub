import { IBestORMInit, ORM } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from './DatabaseConfig';
import { Focus, Idea, Plan, Todo, TodoCategory, User } from '../models';

/**
 * 应用数据库入口。
 * 负责初始化 IBest-ORM 并完成当前 MVP 所需表结构迁移。
 */
export class AppDatabase {
  private static instance: AppDatabase = new AppDatabase();
  private ormInstance: ORM | null = null;
  private initialized: boolean = false;

  static getInstance(): AppDatabase {
    return AppDatabase.instance;
  }

  async initialize(context: object): Promise<void> {
    if (this.initialized && this.ormInstance !== null) {
      return;
    }

    this.ormInstance = await IBestORMInit(context, {
      name: DatabaseConfig.DB_NAME,
      debug: true
    });
    this.ormInstance.migrate(Plan, Todo, TodoCategory, Focus, Idea, User);
    this.initialized = true;
  }

  isReady(): boolean {
    return this.initialized && this.ormInstance !== null;
  }

  async close(): Promise<void> {
    if (this.ormInstance !== null) {
      await this.ormInstance.close();
    }
    this.ormInstance = null;
    this.initialized = false;
  }
}
