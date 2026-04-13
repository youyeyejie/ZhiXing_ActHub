import { ThemeManager, ThemeMode } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow } from './AppConstants';
import { FocusTimerEngine } from '../core/services/FocusTimerEngine'; // <-- 新增引入

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
  private _nav: AppNav = new AppNav();
  private _focusEngine: FocusTimerEngine = new FocusTimerEngine(); // <-- 新增：实例化全局计时引擎
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
   * 返回全局专注计时引擎实例。
   */
  get focusEngine(): FocusTimerEngine {
    return this._focusEngine; // <-- 新增：提供外部访问接口
  }

  /**
   * 应用主题偏好。
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