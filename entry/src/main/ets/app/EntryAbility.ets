import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../core/database/AppDatabase';
import { StatusBarService } from '../core/services/StatusBarService';
import { ThemeMode } from '../core/theme/ThemeManager';
import { useAppState } from './AppStates';

const DOMAIN = 0x0000;

/**
 * 类功能简介：
 * - 应用主 Ability 入口，负责生命周期、窗口初始化与数据库预热。
 *
 * 可传入项：
 * - 生命周期方法接收系统分发的 `Want`、`Configuration` 与 `WindowStage` 参数。
 *
 * 返回行为：
 * - 根据生命周期驱动主题同步、窗口配置和页面加载。
 *
 * 副作用：
 * - 会写入 AppStorage、配置系统窗口、初始化数据库并加载首页。
 */
export default class EntryAbility extends UIAbility {
  private app = useAppState();

  /**
   * 根据系统配置判断是否处于深色模式。
   */
  private isSystemDarkMode(colorMode: ConfigurationConstant.ColorMode | undefined): boolean {
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  /**
   * 读取用户偏好的主题模式。
   * 未设置或异常值时回退到 SYSTEM。
   */
  private readPreferredThemeMode(): ThemeMode {
    const value: Object | undefined = AppStorage.get('preferredThemeMode');
    if (value === ThemeMode.DARK) {
      return ThemeMode.DARK;
    }
    if (value === ThemeMode.LIGHT) {
      return ThemeMode.LIGHT;
    }
    return ThemeMode.SYSTEM;
  }

  /**
   * 同步主题状态到 AppState。
   */
  private syncTheme(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    this.app.applyThemePreference(this.readPreferredThemeMode(), this.isSystemDarkMode(colorMode));
  }

  /**
   * Ability 创建时初始化全局存储和主题状态。
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      hilog.info(DOMAIN, 'testTag', 'Set colorMode to COLOR_MODE_NOT_SET');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    AppStorage.setOrCreate('preferredThemeMode', ThemeMode.SYSTEM);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    AppStorage.setOrCreate('systemDarkMode', this.isSystemDarkMode(this.context.config.colorMode));
    this.syncTheme(this.context.config.colorMode);
  }

  /**
   * 系统配置变化时更新主题相关状态。
   */
  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.set('currentColorMode', newConfig.colorMode);
    AppStorage.set('systemDarkMode', this.isSystemDarkMode(newConfig.colorMode));
    this.syncTheme(newConfig.colorMode);
    hilog.info(DOMAIN, 'testTag', 'Configuration updated. New colorMode: %{public}d', newConfig.colorMode);
  }

  /**
   * Ability 销毁回调。
   */
  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * 主窗口创建后执行窗口样式配置、数据库初始化和页面加载。
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      StatusBarService.bindMainWindow(mainWindow);
      mainWindow.setWindowLayoutFullScreen(true);
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#18222F',
        navigationBarContentColor: '#18222F'
      });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to configure main window. Cause: %{public}s', JSON.stringify(err));
      return;
    }

    AppDatabase.getInstance()
      .initialize(this.context)
      .then((): void => {
        windowStage.loadContent('app/App', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
        });
      })
      .catch((err: Error): void => {
        hilog.error(DOMAIN, 'testTag', 'Failed to initialize database. Cause: %{public}s', JSON.stringify(err));
      });
  }

  /**
   * 主窗口销毁时释放窗口和数据库资源。
   */
  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    StatusBarService.unbindMainWindow();
    AppDatabase.getInstance().close();
  }

  /**
   * Ability 进入前台。
   */
  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    try {
      useAppState().focusEngine.enterForeground();
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', 'Failed to call enterForeground: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * Ability 进入后台。
   */
  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    try {
      useAppState().focusEngine.enterBackground();
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', 'Failed to call enterBackground: %{public}s', JSON.stringify(e));
    }
  }

}
