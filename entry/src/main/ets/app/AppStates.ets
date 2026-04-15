import { ThemeManager, ThemeMode } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow, AppPreferenceKey } from './AppConstants';
import { AuthService } from '../core/services/AuthService';
import { FocusTimerEngine } from '../core/services/FocusTimerEngine';
import { WhiteNoisePlayer } from '../core/services/WhiteNoisePlayer';
import { PreferenceStorage } from '../core/storage/PreferenceStorage';
import { User } from '../core/models/User';



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
  private preferenceStorage: PreferenceStorage = PreferenceStorage.getInstance();
  private currentUserValue: User | null = null;

  @Trace public flow: AppFlow = AppFlow.SPLASH;
  @Trace public currentUserId: string = '';
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
    return this.currentUserId.length > 0;
  }
  applyThemePreference(mode: ThemeMode, systemDarkMode: boolean): void {
    this.themeManager.set(mode);
    this.themeManager.setSystemDark(systemDarkMode);
  }

  setPreferredThemeMode(mode: ThemeMode): void {
    AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, mode);
    this.applyThemePreference(mode, this.readSystemDarkMode());
    this.preferenceStorage.setStringSync(AppPreferenceKey.PREFERRED_THEME_MODE, mode);
  }

  toggleThemeMode(): void {
    const nextMode: ThemeMode = this.theme.isDark ? ThemeMode.LIGHT : ThemeMode.DARK;
    this.setPreferredThemeMode(nextMode);
  }

  async bootstrap(): Promise<void> {
    this.enterSplash();
    try {
      const storedUserId: string = await this.preferenceStorage.getString(
        AppPreferenceKey.SESSION_USER_ID,
        '',
      );
      if (`${storedUserId}`.trim().length === 0) {
        this.applyCurrentUser(null);
        this.enterAuth();
        return;
      }

      const restoredUser: User | null = await this.authService.restoreSession(storedUserId);
      if (restoredUser === null) {
        await this.clearStoredSession();
        this.applyCurrentUser(null);
        this.enterAuth();
        return;
      }

      this.applyCurrentUser(restoredUser);
      this.enterMain();
    } catch (_error) {
      this.applyCurrentUser(null);
      this.enterAuth();
    }
  }

  async login(account: string, password: string): Promise<AuthActionResult> {
    const user: User | null = await this.authService.login(account, password);
    if (user === null) {
      return {
        success: false,
        message: '账号或密码错误',
      };
    }

    this.applyCurrentUser(user);
    await this.persistSession(user);
    this.enterMain();
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
    await this.persistSession(user);
    this.enterMain();
    return {
      success: true,
      message: '注册成功，' + user.name,
    };
  }

  async logout(): Promise<void> {
    this.authService.logout();
    this.applyCurrentUser(null);
    await this.clearStoredSession();
    this.enterAuth();
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
    this.currentUserId = user !== null ? user.id : '';
    this.currentUserName = user !== null ? user.name : '';
    this.currentUserAvatar = user !== null ? user.avatar : '';
  }

  private async persistSession(user: User): Promise<void> {
    await this.preferenceStorage.setString(AppPreferenceKey.SESSION_USER_ID, user.id);
  }

  private async clearStoredSession(): Promise<void> {
    await this.preferenceStorage.remove(AppPreferenceKey.SESSION_USER_ID);
  }

  private readSystemDarkMode(): boolean {
    return AppStorage.get('systemDarkMode') === true;
  }
}

const APP_STATE: AppState = new AppState();

export function useAppState(): AppState {
  return APP_STATE;
}
