import { ThemeManager, ThemeMode } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow, AppPreferenceKey } from './AppConstants';
import { common } from '@kit.AbilityKit';
import { AuthService } from '../core/services/AuthService';
import { CalendarReminderService } from '../core/services/CalendarReminderService';
import { FocusTimerEngine } from '../core/services/FocusTimerEngine';
import { NotificationService } from '../core/services/NotificationService';
import { StatusBarService } from '../core/services/StatusBarService';
import { WhiteNoisePlayer } from '../core/services/WhiteNoisePlayer';
import { User } from '../core/models/User';
import { UserPreferenceRepository } from '../core/repositories/UserPreferenceRepository';



/**
 * 组件功能简介：
 * - 认证动作返回结构，统一封装认证是否成功与提示消息。
 *
 * 可传入项：
 * - `success`: 认证结果。
 * - `message`: 反馈文案。
 *
 * 返回行为：
 * - 作为登录/注册方法返回值类型。
 *
 * 副作用：
 * - 无。
 */
export interface AuthActionResult {
  success: boolean;
  message: string;
}

/**
 * 组件功能简介：
 * - AI 洞察单条会话记录状态对象。
 *
 * 可传入项：
 * - 通过字段写入 `id/mode/keywords/summary/fullContent` 等状态。
 *
 * 返回行为：
 * - 提供 `reset()` 清空当前记录状态。
 *
 * 副作用：
 * - `reset()` 会重置全部追踪字段。
 */
@ObservedV2
export class AIInsightSessionRecordState {
  @Trace public id: number = 0;
  @Trace public mode: string = 'global';
  @Trace public createdAt: number = 0;
  @Trace public keywords: string[] = [];
  @Trace public summary: string = '';
  @Trace public fullContent: string = '';
  @Trace public noteCount: number = 0;
  @Trace public totalLength: number = 0;
  @Trace public pending: boolean = false;

  reset(): void {
    this.id = 0;
    this.mode = 'global';
    this.createdAt = 0;
    this.keywords = [];
    this.summary = '';
    this.fullContent = '';
    this.noteCount = 0;
    this.totalLength = 0;
    this.pending = false;
  }
}

/**
 * 组件功能简介：
 * - AI 洞察会话聚合状态，维护生成过程与当前记录。
 *
 * 可传入项：
 * - 通过字段写入 `isGenerating/generatingText/errorMessage`。
 *
 * 返回行为：
 * - 通过 `activeRecord` 提供当前记录对象访问。
 *
 * 副作用：
 * - `reset()` 会清空会话生成态与记录态。
 */
@ObservedV2
export class AIInsightSessionState {
  private activeRecordState: AIInsightSessionRecordState = new AIInsightSessionRecordState();
  @Trace public isGenerating: boolean = false;
  @Trace public generatingText: string = '';
  @Trace public errorMessage: string = '';

  get activeRecord(): AIInsightSessionRecordState {
    return this.activeRecordState;
  }

  reset(): void {
    this.activeRecordState.reset();
    this.isGenerating = false;
    this.generatingText = '';
    this.errorMessage = '';
  }
}

/**
 * 组件功能简介：
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
  private aiInsightSessionState: AIInsightSessionState = new AIInsightSessionState();
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
  @Trace public hasGrantedCalendarPermissionOnLaunch: boolean = false;
  @Trace public hasSyncedCalendarRemindersOnLaunch: boolean = false;
  @Trace public focusStatsRefreshVersion: number = 0;

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

  get aiInsightSession(): AIInsightSessionState {
    return this.aiInsightSessionState;
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
    StatusBarService.syncContentWithTheme(this.themeManager.palette).catch(() => {
      return;
    });
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
      await this.syncCalendarRemindersAfterLaunchIfReady();
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
    this.hasGrantedCalendarPermissionOnLaunch = granted;
    await this.syncCalendarRemindersAfterLaunchIfReady();
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

  notifyFocusStatsShouldRefresh(): void {
    this.focusStatsRefreshVersion += 1;
  }

  async syncCalendarRemindersForCurrentUser(): Promise<void> {
    if (!this.isLoggedIn) {
      return;
    }
    await this.calendarReminderService.registerPlanReminder();
  }

  private async syncCalendarRemindersAfterLaunchIfReady(): Promise<void> {
    if (this.hasSyncedCalendarRemindersOnLaunch) {
      return;
    }
    if (!this.hasGrantedCalendarPermissionOnLaunch) {
      return;
    }
    if (!this.isLoggedIn) {
      return;
    }
    this.hasSyncedCalendarRemindersOnLaunch = true;
    await this.syncCalendarRemindersForCurrentUser();
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

/**
 * 组件功能简介：
 * - 获取应用运行态单例。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回全局唯一 `AppState` 实例。
 *
 * 副作用：
 * - 无。
 */
export function useAppState(): AppState {
  return APP_STATE;
}
