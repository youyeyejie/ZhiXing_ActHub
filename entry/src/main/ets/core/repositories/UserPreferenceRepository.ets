import { UserPreference } from '../models/UserPreference';
import { BaseRepository } from './BaseRepository';
import { RepositoryScope } from '../database/RepositoryScope';

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
