import { User } from '../models/User';
import { AppSettingRepository } from '../repositories/AppSettingRepository';
import { UserRepository } from '../repositories/UserRepository';
import { UserDatabase } from '../database/UserDatabase';
import { AppDatabase } from '../database/AppDatabase';
import { UserPreferenceRepository } from '../repositories/UserPreferenceRepository';
import { AppPreferenceKey } from '../../app/AppConstants';
import { ThemeMode } from '../theme/ThemeManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AuthService';

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
    hilog.info(DOMAIN, TAG, 'login start account=%{public}s', account);
    const user: User | null = await this.userRepository.login(account, password);
    if (user !== null) {
      hilog.info(DOMAIN, TAG, 'login user id=%{public}s name=%{public}s', user.id, user.name);
      await this.openUserDatabase(user);
      await this.appSettingRepository.setString('session.username', user.name);
      await this.appSettingRepository.setBoolean('session.logged_in', true);
      await this.ensureUserDefaults();
    } else {
      hilog.info(DOMAIN, TAG, 'login failed');
    }
    this.currentUser = user;
    return user;
  }

  async register(account: string, password: string): Promise<User | null> {
    hilog.info(DOMAIN, TAG, 'register start account=%{public}s', account);
    const user: User | null = await this.userRepository.register(account, password);
    if (user !== null) {
      hilog.info(DOMAIN, TAG, 'register user id=%{public}s name=%{public}s', user.id, user.name);
      await this.openUserDatabase(user);
      await this.appSettingRepository.setString('session.username', user.name);
      await this.appSettingRepository.setBoolean('session.logged_in', true);
      await this.ensureUserDefaults();
    } else {
      hilog.info(DOMAIN, TAG, 'register failed');
    }
    this.currentUser = user;
    return user;
  }

  async restoreSession(): Promise<User | null> {
    hilog.info(DOMAIN, TAG, 'restoreSession start');
    const loggedIn: boolean = await this.appSettingRepository.getBoolean('session.logged_in', false);
    const username: string = await this.appSettingRepository.getString('session.username', '');
    if (!loggedIn || username.trim().length === 0) {
      hilog.info(DOMAIN, TAG, 'restoreSession no valid session');
      this.currentUser = null;
      return null;
    }
    hilog.info(DOMAIN, TAG, 'restoreSession session username=%{public}s logged=%{public}s',
      username, loggedIn ? '1' : '0');

    const user: User | null = await this.userRepository.findByAccount(username);
    hilog.info(DOMAIN, TAG, 'restoreSession findByAccount=%{public}s', user !== null ? user.name : 'null');
    if (user !== null) {
      await this.openUserDatabase(user);
      await this.ensureUserDefaults();
      hilog.info(DOMAIN, TAG, 'restoreSession success id=%{public}s name=%{public}s', user.id, user.name);
    } else {
      hilog.info(DOMAIN, TAG, 'restoreSession user missing');
    }
    this.currentUser = user;
    return user;
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  async logout(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'logout start');
    await this.appSettingRepository.setBoolean('session.logged_in', false);
    await this.appSettingRepository.setString('session.username', '');
    await UserDatabase.getInstance().close();
    this.currentUser = null;
    hilog.info(DOMAIN, TAG, 'logout done');
  }

  private async openUserDatabase(user: User): Promise<void> {
    hilog.info(DOMAIN, TAG, 'openUserDatabase user=%{public}s id=%{public}s', user.name, user.id);
    await UserDatabase.getInstance().initialize(AppDatabase.getInstance().getContext(), user.name);
    hilog.info(DOMAIN, TAG, 'openUserDatabase ready current=%{public}s', UserDatabase.getInstance().getCurrentUsername());
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
    hilog.info(DOMAIN, TAG, 'ensureUserDefaults theme=%{public}s', mode);

    let notificationFlag: string = await this.userPreferenceRepository.getString(
      AppPreferenceKey.NOTIFICATION_ENABLED,
      '',
    );
    if (notificationFlag.length === 0) {
      hilog.info(DOMAIN, TAG, 'ensureUserDefaults notification missing, defer to NotificationService');
    } else {
      await this.userPreferenceRepository.setBoolean(
        AppPreferenceKey.NOTIFICATION_ENABLED,
        notificationFlag === '1',
      );
    }
    hilog.info(DOMAIN, TAG, 'ensureUserDefaults notification=%{public}s', notificationFlag);

    let reminderFlag: string = await this.userPreferenceRepository.getString(
      AppPreferenceKey.PLAN_REMINDER_ENABLED,
      '',
    );
    if (reminderFlag.length === 0) {
      reminderFlag = '0';
    }
    await this.userPreferenceRepository.setBoolean(
      AppPreferenceKey.PLAN_REMINDER_ENABLED,
      reminderFlag === '1',
    );
    hilog.info(DOMAIN, TAG, 'ensureUserDefaults reminder=%{public}s', reminderFlag);
  }
}
