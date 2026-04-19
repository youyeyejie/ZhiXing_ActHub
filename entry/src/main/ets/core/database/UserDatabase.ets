import { IBestORMInit, ORM } from '@ibestservices/ibest-orm';
import { common } from '@kit.AbilityKit';
import { DatabaseConfig } from './DatabaseConfig';
import { AIInsight, Focus, Idea, Plan, Todo, TodoCategory, UserPreference } from '../models';
import { PlanRepository } from '../repositories/PlanRepository';
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';
import { HashUtils } from '../security/HashUtils';

/**
 * 类功能简介：
 * - 当前登录用户数据库入口，负责按用户名哈希创建独立数据库并维护连接生命周期。
 */
export class UserDatabase {
  private static instance: UserDatabase = new UserDatabase();
  private static readonly SCHEMA_VERSION_KEY: string = 'schema.user_version';
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
    await this.runMigrations();
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

  private async runMigrations(): Promise<void> {
    const preferences = new UserPreferenceRepository();
    const versionText: string = await preferences.getString(UserDatabase.SCHEMA_VERSION_KEY, '0');
    const currentVersion: number = Number(versionText);

    if (currentVersion < 1) {
      await this.migrateToVersion1();
    }

    await preferences.setString(UserDatabase.SCHEMA_VERSION_KEY, `${DatabaseConfig.USER_SCHEMA_VERSION}`);
  }

  private async migrateToVersion1(): Promise<void> {
    const planRepository = new PlanRepository();
    const plans: Array<Plan> = await planRepository.findAll();
    for (let index = 0; index < plans.length; index++) {
      const plan = plans[index];
      let changed: boolean = false;

      if (plan.version <= 0) {
        plan.version = 1;
        changed = true;
      }

      if (plan.notifyVersion < 0) {
        plan.notifyVersion = 0;
        changed = true;
      }

      if (changed) {
        await planRepository.save(plan);
      }
    }
  }
}
