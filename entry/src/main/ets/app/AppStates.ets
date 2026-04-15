import { ThemeManager, ThemeMode } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow, AppPreferenceKey } from './AppConstants';
import { AuthService } from '../core/services/AuthService';
import { FocusTimerEngine } from '../core/services/FocusTimerEngine';
import { WhiteNoisePlayer } from '../core/services/WhiteNoisePlayer';
import { User } from '../core/models/User';
import { UserPreferenceRepository } from '../core/repositories/UserPreferenceRepository';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AppState';



export interface AuthActionResult {
  success: boolean;
  message: string;
}

/**
 * 类功能简介：
 * - 应用运行态单例，统一管理主题、导航与流程状态。
 *
 * 可传入项：
 * - `applyThemePreference(mode, systemDarkMode)` 传入主题模式与系统深色状态。
 *
 * 返回行为：
 * - 提供全局 `theme/nav` 访问与流程切换能力。
 * - 提供全局 `core/services/focusEngine`访问能力。
 *
 * 副作用：
 * - 会更新响应式应用状态并驱动界面刷新。
 */
@ObservedV2
export class AppState {
  private themeManager: ThemeManager = new ThemeManager();
  private navState: AppNav = new AppNav();
  private focusTimerEngine: FocusTimerEngine = new FocusTimerEngine();
  private _whiteNoisePlayer: WhiteNoisePlayer = new WhiteNoisePlayer();
  private authService: AuthService = new AuthService();
  private currentUserValue: User | null = null;
  private userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();

  @Trace public flow: AppFlow = AppFlow.SPLASH;
  @Trace public currentUserId: number = 0;
  @Trace public currentUserName: string = '';
  @Trace public currentUserAvatar: string = '';

  get theme(): ThemeManager {
    return this.themeManager;
  }

  get nav(): AppNav {
    return this.navState;
  }

  get focusEngine(): FocusTimerEngine {
    return this.focusTimerEngine;
  }
  /**
   * 返回白噪音播放器。
   */
  get whiteNoisePlayer(): WhiteNoisePlayer {
    return this._whiteNoisePlayer;
  }
  /**
   * 应用主题偏好。
   */

  get currentUser(): User | null {
    return this.currentUserValue;
  }

  get isLoggedIn(): boolean {
    return this.currentUserValue !== null;
  }
  applyThemePreference(mode: ThemeMode, systemDarkMode: boolean): void {
    this.themeManager.set(mode);
    this.themeManager.setSystemDark(systemDarkMode);
  }

  async setPreferredThemeMode(mode: ThemeMode): Promise<void> {
    AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, mode);
    this.applyThemePreference(mode, this.readSystemDarkMode());
    if (this.isLoggedIn) {
      await this.userPreferenceRepository.setString(AppPreferenceKey.PREFERRED_THEME_MODE, mode);
    }
  }

  toggleThemeMode(): void {
    const nextMode: ThemeMode = this.theme.isDark ? ThemeMode.LIGHT : ThemeMode.DARK;
    this.setPreferredThemeMode(nextMode);
  }

  async bootstrap(): Promise<void> {
    this.enterSplash();
    hilog.info(DOMAIN, TAG, 'bootstrap start');
    try {
      const restoredUser: User | null = await this.authService.restoreSession();
      if (restoredUser === null) {
        hilog.info(DOMAIN, TAG, 'bootstrap no restored user -> AUTH');
        this.applyCurrentUser(null);
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
        this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
        this.enterAuth();
        return;
      }

      hilog.info(DOMAIN, TAG, 'bootstrap restored user id=%{public}s name=%{public}s',
        restoredUser.id, restoredUser.name);
      this.applyCurrentUser(restoredUser);
      try {
        const storedThemeMode: string = await this.userPreferenceRepository.getString(
          AppPreferenceKey.PREFERRED_THEME_MODE,
          ThemeMode.SYSTEM,
        );
        const preferredThemeMode: ThemeMode = this.normalizeThemeMode(storedThemeMode);
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, preferredThemeMode);
        this.applyThemePreference(preferredThemeMode, this.readSystemDarkMode());
        hilog.info(DOMAIN, TAG, 'bootstrap theme=%{public}s', preferredThemeMode);
      } catch (_error) {
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
        this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
        hilog.info(DOMAIN, TAG, 'bootstrap theme restore failed -> SYSTEM');
      }
      this.enterMain();
      hilog.info(DOMAIN, TAG, 'bootstrap -> MAIN');
    } catch (_error) {
      hilog.info(DOMAIN, TAG, 'bootstrap exception -> AUTH');
      this.applyCurrentUser(null);
      AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
      this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
      this.enterAuth();
    }
  }

  async login(account: string, password: string): Promise<AuthActionResult> {
    hilog.info(DOMAIN, TAG, 'login start account=%{public}s', account);
    const user: User | null = await this.authService.login(account, password);
    if (user === null) {
      hilog.info(DOMAIN, TAG, 'login failed');
      return {
        success: false,
        message: '账号或密码错误',
      };
    }

    this.applyCurrentUser(user);
    await this.loadUserPreferences();
    this.enterMain();
    hilog.info(DOMAIN, TAG, 'login success id=%{public}s name=%{public}s', user.id, user.name);
    return {
      success: true,
      message: '欢迎回来，' + user.name,
    };
  }

  async register(account: string, password: string): Promise<AuthActionResult> {
    const user: User | null = await this.authService.register(account, password);
    if (user === null) {
      return {
        success: false,
        message: '注册失败，账号可能已存在',
      };
    }

    this.applyCurrentUser(user);
    await this.loadUserPreferences();
    this.enterMain();
    return {
      success: true,
      message: '注册成功，' + user.name,
    };
  }

  async logout(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'logout start');
    await this.authService.logout();
    this.applyCurrentUser(null);
    AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
    this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
    this.enterAuth();
    hilog.info(DOMAIN, TAG, 'logout -> AUTH');
  }

  enterSplash(): void {
    this.flow = AppFlow.SPLASH;
  }

  enterAuth(): void {
    this.flow = AppFlow.AUTH;
  }

  enterMain(): void {
    this.flow = AppFlow.MAIN;
  }

  private applyCurrentUser(user: User | null): void {
    this.currentUserValue = user;
    this.currentUserId = user !== null ? user.id : 0;
    this.currentUserName = user !== null ? user.name : '';
    this.currentUserAvatar = user !== null ? user.avatar : '';
  }

  private readSystemDarkMode(): boolean {
    return AppStorage.get<boolean>('systemDarkMode') === true;
  }

  private normalizeThemeMode(value: string): ThemeMode {
    if (value === ThemeMode.DARK) {
      return ThemeMode.DARK;
    }
    if (value === ThemeMode.LIGHT) {
      return ThemeMode.LIGHT;
    }
    return ThemeMode.SYSTEM;
  }

  private async loadUserPreferences(): Promise<void> {
    if (!this.isLoggedIn) {
      return;
    }
    const storedThemeMode: string = await this.userPreferenceRepository.getString(
      AppPreferenceKey.PREFERRED_THEME_MODE,
      ThemeMode.SYSTEM,
    );
    const preferredThemeMode: ThemeMode = this.normalizeThemeMode(storedThemeMode);
    AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, preferredThemeMode);
    this.applyThemePreference(preferredThemeMode, this.readSystemDarkMode());
  }
}

const APP_STATE: AppState = new AppState();

export function useAppState(): AppState {
  return APP_STATE;
}
