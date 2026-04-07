import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../core/database/AppDatabase';
import { ThemeMode } from '../core/theme/ThemeManager';
import { useAppState } from './AppStates';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private app = useAppState();

  private isSystemDarkMode(colorMode: ConfigurationConstant.ColorMode | undefined): boolean {
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

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

  private syncTheme(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    this.app.applyThemePreference(this.readPreferredThemeMode(), this.isSystemDarkMode(colorMode));
  }

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

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.set('currentColorMode', newConfig.colorMode);
    AppStorage.set('systemDarkMode', this.isSystemDarkMode(newConfig.colorMode));
    this.syncTheme(newConfig.colorMode);
    hilog.info(DOMAIN, 'testTag', 'Configuration updated. New colorMode: %{public}d', newConfig.colorMode);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
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

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    AppDatabase.getInstance().close();
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

}
