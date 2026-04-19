import { window } from '@kit.ArkUI';
import { ThemePalette } from '../theme/ThemePalette';

/**
 * 类功能简介：
 * - 状态栏显隐服务，统一管理主窗口状态栏开关。
 *
 * 可传入项：
 * - `bindMainWindow(mainWindow)` 传入主窗口实例。
 *
 * 返回行为：
 * - 提供绑定、解绑、显示和隐藏状态栏能力。
 *
 * 副作用：
 * - 会调用系统窗口 API 修改状态栏可见性。
 */
export class StatusBarService {
  private static mainWindow: window.Window | null = null;

  static bindMainWindow(mainWindow: window.Window): void {
    StatusBarService.mainWindow = mainWindow;
  }

  static unbindMainWindow(): void {
    StatusBarService.mainWindow = null;
  }

  static hideStatusBar(): Promise<void> {
    return StatusBarService.setStatusBarVisible(false);
  }

  static showStatusBar(): Promise<void> {
    return StatusBarService.setStatusBarVisible(true);
  }

  static syncContentWithTheme(palette: ThemePalette): Promise<void> {
    const mainWindow = StatusBarService.mainWindow;
    if (mainWindow === null) {
      return Promise.resolve();
    }

    return mainWindow.setWindowSystemBarProperties({
      statusBarContentColor: palette.textPrimary,
      navigationBarContentColor: palette.textPrimary,
    }).then(() => {
      return;
    }).catch(() => {
      return;
    });
  }

  private static setStatusBarVisible(visible: boolean): Promise<void> {
    const mainWindow = StatusBarService.mainWindow;
    if (mainWindow === null) {
      return Promise.resolve();
    }

    return mainWindow.setSpecificSystemBarEnabled('status', visible)
      .then(() => {
        return;
      })
      .catch(() => {
        return;
      });
  }
}
