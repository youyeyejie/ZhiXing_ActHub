import { AppDatabase } from '../database/AppDatabase';
import { AppSetting } from '../models/AppSetting';

/**
 * 组件功能简介：
 * - 应用设置仓储，封装应用级字符串/布尔配置的读写。
 *
 * 可传入项：
 * - `getString/getBoolean` 接收配置键与回退值。
 * - `setString/setBoolean` 接收配置键与待写入值。
 *
 * 返回行为：
 * - 返回配置读取结果，或在写入后完成 Promise。
 *
 * 副作用：
 * - 会写入应用数据库 `app_settings` 表并更新时间戳。
 */
export class AppSettingRepository {
  /**
   * 组件功能简介：
   * - 构造 AppSetting 查询入口。
   *
   * 可传入项：
   * - 无。
   *
   * 返回行为：
   * - 返回 ORM QueryBuilder。
   *
   * 副作用：
   * - 无。
   */
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
