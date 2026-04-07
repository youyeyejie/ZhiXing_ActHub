import { window } from '@kit.ArkUI';

/**
 * 状态栏显隐控制服务。
 * 由 EntryAbility 绑定主窗口后，供页面层按交互时机切换状态栏显隐。
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
