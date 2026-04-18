import { AppDatabase } from '../database/AppDatabase';
import { AppSetting } from '../models/AppSetting';

export class AppSettingRepository {
  private get query() {
    return AppDatabase.getInstance().getOrm().query(AppSetting);
  }

  async getString(key: string, fallback: string = ''): Promise<string> {
    const setting: AppSetting | null = this.query.where('key', key).first();
    if (setting === null) {
      return fallback;
    }
    return setting.value;
  }

  async setString(key: string, value: string): Promise<void> {
    let setting: AppSetting | null = this.query.where('key', key).first();
    const now: number = Date.now();
    if (setting === null) {
      setting = new AppSetting();
    }
    setting.key = key;
    setting.value = value;
    setting.updatedAt = now;
    AppDatabase.getInstance().getOrm().save<AppSetting>(setting);
  }

  async getBoolean(key: string, fallback: boolean = false): Promise<boolean> {
    const value: string = await this.getString(key, fallback ? '1' : '0');
    return value === '1';
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    await this.setString(key, value ? '1' : '0');
  }
}
