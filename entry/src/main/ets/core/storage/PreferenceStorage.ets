/**
 * 偏好设置存储占位。
 * TODO: 后续封装登录态、主题模式和用户配置持久化。
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
