import { IBestORMInit, ORM } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from './DatabaseConfig';
import { Focus, Idea, Plan, Todo, TodoCategory, User } from '../models';

/**
 * 类功能简介：
 * - 应用数据库入口单例，负责 ORM 初始化、迁移和关闭。
 *
 * 可传入项：
 * - `initialize(context)` 的 `context` 为应用上下文对象。
 *
 * 返回行为：
 * - 提供数据库初始化状态判断、实例获取与资源释放能力。
 *
 * 副作用：
 * - 初始化时会触发 ORM 迁移并持有数据库连接。
 * - `close` 会释放连接并重置初始化状态。
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
