import { User } from '../models/User';
import { AppSettingRepository } from '../repositories/AppSettingRepository';
import { UserRepository } from '../repositories/UserRepository';
import { UserDatabase } from '../database/UserDatabase';
import { AppDatabase } from '../database/AppDatabase';
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';
import { AppPreferenceKey } from '../../app/AppConstants';
import { ThemeMode } from '../theme/ThemeManager';

/**
 * 组件功能简介：
 * - 认证服务，封装登录、注册、会话恢复与退出流程。
 *
 * 可传入项：
 * - `login/register` 接收账号与密码。
 * - 其它方法使用数据库中已保存的会话信息。
 *
 * 返回行为：
 * - 返回当前用户对象或 `null`，并维护会话状态。
 *
 * 副作用：
 * - 会写入会话设置、初始化用户数据库并更新用户默认偏好。
 */
export class AuthService {
  private currentUser: User | null = null;

  private get userRepository(): UserRepository {
    return new UserRepository();
  }

  private get appSettingRepository(): AppSettingRepository {
    return new AppSettingRepository();
  }

  private get userPreferenceRepository(): UserPreferenceRepository {
    return new UserPreferenceRepository();
  }

  async login(account: string, password: string): Promise<User | null> {
    const user: User | null = await this.userRepository.login(account, password);
    if (user !== null) {
      await this.openUserDatabase(user);
      await this.appSettingRepository.setString('session.username', user.name);
      await this.appSettingRepository.setBoolean('session.logged_in', true);
      await this.ensureUserDefaults();
    }
    this.currentUser = user;
    return user;
  }

  async register(account: string, password: string): Promise<User | null> {
    const user: User | null = await this.userRepository.register(account, password);
    if (user !== null) {
      await this.openUserDatabase(user);
      await this.appSettingRepository.setString('session.username', user.name);
      await this.appSettingRepository.setBoolean('session.logged_in', true);
      await this.ensureUserDefaults();
    }
    this.currentUser = user;
    return user;
  }

  async restoreSession(): Promise<User | null> {
    const loggedIn: boolean = await this.appSettingRepository.getBoolean('session.logged_in', false);
    const username: string = await this.appSettingRepository.getString('session.username', '');
    if (!loggedIn || username.trim().length === 0) {
      this.currentUser = null;
      return null;
    }

    const user: User | null = await this.userRepository.findByAccount(username);
    if (user !== null) {
      await this.openUserDatabase(user);
      await this.ensureUserDefaults();
    }
    this.currentUser = user;
    return user;
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  async logout(): Promise<void> {
    await this.appSettingRepository.setBoolean('session.logged_in', false);
    await this.appSettingRepository.setString('session.username', '');
    await UserDatabase.getInstance().close();
    this.currentUser = null;
  }

  private async openUserDatabase(user: User): Promise<void> {
    await UserDatabase.getInstance().initialize(AppDatabase.getInstance().getContext(), user.name);
  }

  private async ensureUserDefaults(): Promise<void> {
    let mode: string = await this.userPreferenceRepository.getString(
      AppPreferenceKey.PREFERRED_THEME_MODE,
      '',
    );
    if (mode.length === 0) {
      mode = ThemeMode.SYSTEM;
    }
    await this.userPreferenceRepository.setString(AppPreferenceKey.PREFERRED_THEME_MODE, mode);

    let notificationFlag: string = await this.userPreferenceRepository.getString(
      AppPreferenceKey.NOTIFICATION_ENABLED,
      '',
    );
    if (notificationFlag.length === 0) {
      notificationFlag = '1';
    }
    await this.userPreferenceRepository.setBoolean(
      AppPreferenceKey.NOTIFICATION_ENABLED,
      notificationFlag === '1',
    );

    let reminderFlag: string = await this.userPreferenceRepository.getString(
      AppPreferenceKey.PLAN_REMINDER_ENABLED,
      '',
    );
    if (reminderFlag.length === 0) {
      reminderFlag = '1';
    }
    await this.userPreferenceRepository.setBoolean(
      AppPreferenceKey.PLAN_REMINDER_ENABLED,
      reminderFlag === '1',
    );
  }
}
