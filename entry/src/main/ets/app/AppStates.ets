import { ThemeManager, ThemeMode } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow } from './AppConstants';

/**
 * 类功能简介：
 * - 应用运行态单例，统一管理主题、导航与流程状态。
 *
 * 可传入项：
 * - `applyThemePreference(mode, systemDarkMode)` 传入主题模式与系统深色状态。
 *
 * 返回行为：
 * - 提供全局 `theme/nav` 访问与流程切换能力。
 *
 * 副作用：
 * - 会更新响应式应用状态并驱动界面刷新。
 */
@ObservedV2
export class AppState {
  private themeManager: ThemeManager = new ThemeManager();
  private _nav: AppNav = new AppNav();
  @Trace public flow: AppFlow = AppFlow.MAIN;

  /**
   * 返回全局主题管理器实例。
   */
  get theme(): ThemeManager {
    return this.themeManager;
  }

  /**
   * 返回全局导航状态对象。
   */
  get nav(): AppNav {
    return this._nav;
  }

  /**
   * 应用主题偏好。
   * @param mode 用户选择的主题模式
   * @param systemDarkMode 当前系统深色模式状态
   */
  applyThemePreference(mode: ThemeMode, systemDarkMode: boolean): void {
    this.themeManager.set(mode);
    this.themeManager.setSystemDark(systemDarkMode);
  }

  /**
   * 切换到启动流程。
   */
  enterSplash(): void {
    this.flow = AppFlow.SPLASH;
  }

  /**
   * 切换到认证流程。
   */
  enterAuth(): void {
    this.flow = AppFlow.AUTH;
  }

  /**
   * 切换到主流程。
   */
  enterMain(): void {
    this.flow = AppFlow.MAIN;
  }
}

const APP_STATE: AppState = new AppState();

/**
 * 获取应用单例状态。
 */
export function useAppState(): AppState {
  return APP_STATE;
}
