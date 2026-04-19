import { UserPreference } from '../models/UserPreference';
import { BaseRepository } from './BaseRepository';
import { RepositoryScope } from '../database/RepositoryScope';

/**
 * 组件功能简介：
 * - 用户偏好仓储，封装当前用户设置项的键值读写。
 *
 * 可传入项：
 * - `getString/getBoolean` 接收键名与默认值。
 * - `setString/setBoolean` 接收键名与目标值。
 *
 * 返回行为：
 * - 返回读取结果或写入完成 Promise。
 *
 * 副作用：
 * - 会写入用户数据库 `user_preferences` 表。
 */
export class UserPreferenceRepository extends BaseRepository<UserPreference> {
  constructor() {
    super(UserPreference, RepositoryScope.USER);
  }

  async getString(key: string, fallback: string = ''): Promise<string> {
    const preference: UserPreference | null = this.query.where('key', key).first();
    if (preference === null) {
      return fallback;
    }
    return preference.value;
  }

  async setString(key: string, value: string): Promise<void> {
    let preference: UserPreference | null = this.query.where('key', key).first();
    const now: number = Date.now();
    if (preference === null) {
      preference = new UserPreference();
      preference.key = key;
      preference.createdAt = now;
    }
    preference.value = value;
    preference.updatedAt = now;
    await this.save(preference);
  }

  async getBoolean(key: string, fallback: boolean = false): Promise<boolean> {
    const value: string = await this.getString(key, fallback ? '1' : '0');
    return value === '1';
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    await this.setString(key, value ? '1' : '0');
  }
}
