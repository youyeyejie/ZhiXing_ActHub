import { ThemeManager, ThemeMode } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow, AppPreferenceKey } from './AppConstants';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../core/services/AuthService';
import { CalendarReminderService } from '../core/services/CalendarReminderService';
import { FocusTimerEngine } from '../core/services/FocusTimerEngine';
import { NotificationService } from '../core/services/NotificationService';
import { WhiteNoisePlayer } from '../core/services/WhiteNoisePlayer';
import { User } from '../core/models/User';
import { UserPreferenceRepository } from '../core/repositories/UserPreferenceRepository';



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
  private calendarReminderService: CalendarReminderService = new CalendarReminderService();
  private currentUserValue: User | null = null;
  private userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();

  @Trace public flow: AppFlow = AppFlow.SPLASH;
  @Trace public currentUserId: number = 0;
  @Trace public currentUserName: string = '';
  @Trace public currentUserAvatar: string = '';
  @Trace public hasRequestedNotificationPermissionOnLaunch: boolean = false;
  @Trace public hasRequestedCalendarPermissionOnLaunch: boolean = false;

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
    try {
      const restoredUser: User | null = await this.authService.restoreSession();
      if (restoredUser === null) {
        this.applyCurrentUser(null);
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
        this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
        this.enterAuth();
        return;
      }
      this.applyCurrentUser(restoredUser);
      try {
        const storedThemeMode: string = await this.userPreferenceRepository.getString(
          AppPreferenceKey.PREFERRED_THEME_MODE,
          ThemeMode.SYSTEM,
        );
        const preferredThemeMode: ThemeMode = this.normalizeThemeMode(storedThemeMode);
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, preferredThemeMode);
        this.applyThemePreference(preferredThemeMode, this.readSystemDarkMode());
      } catch (_error) {
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
        this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
      }
      this.enterMain();
      await this.syncCalendarRemindersForCurrentUser();
    } catch (_error) {
      this.applyCurrentUser(null);
      AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
      this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
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
    await this.loadUserPreferences();
    this.enterMain();
    await this.syncCalendarRemindersForCurrentUser();
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
    await this.syncCalendarRemindersForCurrentUser();
    return {
      success: true,
      message: '注册成功，' + user.name,
    };
  }

  async logout(): Promise<void> {
    if (this.isLoggedIn) {
      await this.calendarReminderService.cancelPlanReminder();
    }
    await this.authService.logout();
    this.applyCurrentUser(null);
    AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
    this.applyThemePreference(ThemeMode.SYSTEM, this.readSystemDarkMode());
    this.enterAuth();
  }

  async tryRequestNotificationPermissionOnLaunch(context: common.UIAbilityContext): Promise<void> {
    if (this.hasRequestedNotificationPermissionOnLaunch) {
      return;
    }
    this.hasRequestedNotificationPermissionOnLaunch = true;
    await NotificationService.requestNotificationPermission(context);
  }

  async tryRequestCalendarPermissionOnLaunch(context: common.UIAbilityContext): Promise<void> {
    if (this.hasRequestedCalendarPermissionOnLaunch) {
      return;
    }
    this.hasRequestedCalendarPermissionOnLaunch = true;
    const granted = await this.calendarReminderService.requestCalendarPermission(context);
    if (granted && this.isLoggedIn) {
      await this.syncCalendarRemindersForCurrentUser();
    }
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

  async syncCalendarRemindersForCurrentUser(): Promise<void> {
    if (!this.isLoggedIn) {
      return;
    }
    await this.calendarReminderService.registerPlanReminder();
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
