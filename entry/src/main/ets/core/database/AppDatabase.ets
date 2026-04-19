import { IBestORMInit, ORM } from '@ibestservices/ibest-orm';
import { DatabaseConfig } from './DatabaseConfig';
import { AppSchemaState, AppSession, AppSetting, User } from '../models';
import { common } from '@kit.AbilityKit';
import { AppSettingRepository } from '../repositories/AppSettingRepository';

/**
 * 组件功能简介：
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
  private context: common.BaseContext | null = null;

  static getInstance(): AppDatabase {
    return AppDatabase.instance;
  }

  async initialize(context: common.BaseContext): Promise<void> {
    if (this.initialized && this.ormInstance !== null) {
      return;
    }

    this.context = context;
    this.ormInstance = await IBestORMInit(context, {
      name: DatabaseConfig.DB_NAME,
      debug: true
    });
    this.ormInstance.migrate(User, AppSetting, AppSession, AppSchemaState);
    await this.runMigrations();
    this.initialized = true;
  }

  isReady(): boolean {
    return this.initialized && this.ormInstance !== null;
  }

  getOrm(): ORM {
    if (this.ormInstance === null) {
      throw new Error('App database has not been initialized.');
    }
    return this.ormInstance;
  }

  getContext(): common.BaseContext {
    if (this.context === null) {
      throw new Error('App database context is not available.');
    }
    return this.context;
  }

  async close(): Promise<void> {
    if (this.ormInstance !== null) {
      await this.ormInstance.close();
    }
    this.ormInstance = null;
    this.initialized = false;
    this.context = null;
  }

  private async runMigrations(): Promise<void> {
    const settings = new AppSettingRepository();
    const versionText: string = await settings.getString('schema.version', '0');
    const currentVersion: number = Number(versionText);

    if (currentVersion < 2) {
      await this.migrateToVersion2();
    }

    await settings.setString('schema.version', `${DatabaseConfig.VERSION}`);
  }

  private async migrateToVersion2(): Promise<void> {
    const orm: ORM = this.getOrm();
    const settings = new AppSettingRepository();

    const schemaQuery = orm.query(AppSchemaState);
    const legacySchema: AppSchemaState | null = schemaQuery.where('id', 'app').first();
    if (legacySchema !== null && legacySchema.schemaVersion > 0) {
      await settings.setString('schema.version', `${legacySchema.schemaVersion}`);
    }

    const sessionQuery = orm.query(AppSession);
    const allSessions: Array<AppSession> = sessionQuery.find();
    let hasLegacyLoggedIn: boolean = false;
    let latestUsername: string = '';
    if (allSessions.length > 0) {
      let latest: AppSession = allSessions[0];
      for (let index = 1; index < allSessions.length; index++) {
        if (allSessions[index].updatedAt > latest.updatedAt) {
          latest = allSessions[index];
        }
      }
      latestUsername = latest.username;
      hasLegacyLoggedIn = latest.isLoggedIn === 1 && latest.username.trim().length > 0;
    }
    await settings.setString('session.username', latestUsername);
    await settings.setBoolean('session.logged_in', hasLegacyLoggedIn);
  }
}
