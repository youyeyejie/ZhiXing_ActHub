import { IBestORMInit, ORM } from '@ibestservices/ibest-orm';
import { common } from '@kit.AbilityKit';
import { AIInsight, Focus, Idea, Plan, Todo, TodoCategory, UserPreference } from '../models';
import { HashUtils } from '../security/HashUtils';

/**
 * 类功能简介：
 * - 当前登录用户数据库入口，负责按用户名哈希创建独立数据库并维护连接生命周期。
 */
export class UserDatabase {
  private static instance: UserDatabase = new UserDatabase();
  private ormInstance: ORM | null = null;
  private initialized: boolean = false;
  private currentUsername: string = '';

  static getInstance(): UserDatabase {
    return UserDatabase.instance;
  }

  async resolveDatabaseFileName(username: string): Promise<string> {
    const normalizedUsername: string = username.trim();
    if (normalizedUsername.length === 0) {
      throw new Error('Username is required for database filename.');
    }
    return await HashUtils.md5Hex(normalizedUsername) + '.db';
  }

  async resolveDatabaseFilePath(context: common.UIAbilityContext, username: string): Promise<string> {
    const filename: string = await this.resolveDatabaseFileName(username);
    return context.databaseDir + '/rdb/' + filename;
  }

  async initialize(context: common.BaseContext, username: string): Promise<void> {
    const normalizedUsername: string = username.trim();
    if (normalizedUsername.length === 0) {
      throw new Error('Username is required for user database initialization.');
    }

    if (this.initialized && this.ormInstance !== null && this.currentUsername === normalizedUsername) {
      return;
    }

    await this.close();

    const filename: string = await this.resolveDatabaseFileName(normalizedUsername);
    this.ormInstance = await IBestORMInit(context, {
      name: filename,
      debug: true
    });
    this.ormInstance.migrate(Plan, Todo, TodoCategory, Focus, Idea, AIInsight, UserPreference);
    this.initialized = true;
    this.currentUsername = normalizedUsername;
  }

  isReady(): boolean {
    return this.initialized && this.ormInstance !== null;
  }

  getOrm(): ORM {
    if (this.ormInstance === null) {
      throw new Error('User database has not been initialized.');
    }
    return this.ormInstance;
  }

  getCurrentUsername(): string {
    return this.currentUsername;
  }

  async close(): Promise<void> {
    if (this.ormInstance !== null) {
      await this.ormInstance.close();
    }
    this.ormInstance = null;
    this.initialized = false;
    this.currentUsername = '';
  }
}
