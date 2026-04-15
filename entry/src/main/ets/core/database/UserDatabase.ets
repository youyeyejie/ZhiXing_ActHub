import { IBestORMInit, ORM } from '@ibestservices/ibest-orm';
import { common } from '@kit.AbilityKit';
import { Focus, Idea, Plan, Todo, TodoCategory, UserPreference } from '../models';
import { HashUtils } from '../security/HashUtils';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'UserDatabase';

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

  async initialize(context: common.BaseContext, username: string): Promise<void> {
    const normalizedUsername: string = username.trim();
    if (normalizedUsername.length === 0) {
      throw new Error('Username is required for user database initialization.');
    }

    if (this.initialized && this.ormInstance !== null && this.currentUsername === normalizedUsername) {
      hilog.info(DOMAIN, TAG, 'initialize skipped current=%{public}s', normalizedUsername);
      return;
    }

    await this.close();

    const filename: string = await HashUtils.md5Hex(normalizedUsername) + '.db';
    hilog.info(DOMAIN, TAG, 'initialize start username=%{public}s file=%{public}s', normalizedUsername, filename);
    this.ormInstance = await IBestORMInit(context, {
      name: filename,
      debug: true
    });
    this.ormInstance.migrate(Plan, Todo, TodoCategory, Focus, Idea, UserPreference);
    this.initialized = true;
    this.currentUsername = normalizedUsername;
    hilog.info(DOMAIN, TAG, 'initialize done current=%{public}s', this.currentUsername);
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
      hilog.info(DOMAIN, TAG, 'close current=%{public}s', this.currentUsername);
      await this.ormInstance.close();
    }
    this.ormInstance = null;
    this.initialized = false;
    this.currentUsername = '';
  }
}
