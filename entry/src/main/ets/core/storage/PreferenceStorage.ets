/**
 * 类功能简介：
 * - 偏好设置存储占位类，预留字符串与布尔配置读写接口。
 * - TODO: 尚未接入真实持久化实现。
 *
 * 可传入项：
 * - 读写方法入参为键名与对应值。
 *
 * 返回行为：
 * - 当前返回 Promise 占位。
 *
 * 副作用：
 * - 当前无实际副作用。
 */
export class PreferenceStorage {
  setString(key: string, value: string): Promise<void> {
    // TODO: 保存字符串配置。
    return Promise.resolve();
  }

  getString(key: string): Promise<string> {
    // TODO: 读取字符串配置。
    return Promise.resolve('');
  }

  setBoolean(key: string, value: boolean): Promise<void> {
    // TODO: 保存布尔配置。
    return Promise.resolve();
  }

  getBoolean(key: string): Promise<boolean> {
    // TODO: 读取布尔配置。
    return Promise.resolve(false);
  }
}
