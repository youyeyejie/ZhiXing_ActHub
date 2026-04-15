import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../core/database/AppDatabase';
import { StatusBarService } from '../core/services/StatusBarService';
import { NotificationService } from '../core/services/NotificationService';
import { ThemeMode } from '../core/theme/ThemeManager';
import { useAppState } from './AppStates';
import { AppPreferenceKey } from './AppConstants';
import { PreferenceStorage } from '../core/storage/PreferenceStorage';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private app = useAppState();

  private isSystemDarkMode(colorMode: ConfigurationConstant.ColorMode | undefined): boolean {
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private readPreferredThemeMode(): ThemeMode {
    const inMemoryValue: Object | undefined = AppStorage.get(AppPreferenceKey.PREFERRED_THEME_MODE);
    if (inMemoryValue === ThemeMode.DARK) {
      return ThemeMode.DARK;
    }
    if (inMemoryValue === ThemeMode.LIGHT) {
      return ThemeMode.LIGHT;
    }

    const storedValue: string = PreferenceStorage.getInstance().getStringSync(
      AppPreferenceKey.PREFERRED_THEME_MODE,
      ThemeMode.SYSTEM,
    );
    if (storedValue === ThemeMode.DARK) {
      return ThemeMode.DARK;
    }
    if (storedValue === ThemeMode.LIGHT) {
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
      hilog.info(DOMAIN, 'EntryAbility', 'Set color mode to COLOR_MODE_NOT_SET');
    } catch (err) {
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to set color mode. %{public}s', JSON.stringify(err));
    }

    PreferenceStorage.getInstance().initialize(this.context);
    const preferredThemeMode: ThemeMode = this.readPreferredThemeMode();
    AppStorage.setOrCreate(AppPreferenceKey.PREFERRED_THEME_MODE, preferredThemeMode);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    AppStorage.setOrCreate('systemDarkMode', this.isSystemDarkMode(this.context.config.colorMode));
    this.syncTheme(this.context.config.colorMode);
    this.app.enterSplash();

    hilog.info(DOMAIN, 'EntryAbility', 'Ability onCreate');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.set('currentColorMode', newConfig.colorMode);
    AppStorage.set('systemDarkMode', this.isSystemDarkMode(newConfig.colorMode));
    this.syncTheme(newConfig.colorMode);
    hilog.info(DOMAIN, 'EntryAbility', 'Configuration updated. %{public}d', newConfig.colorMode);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onWindowStageCreate');

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
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to configure main window. %{public}s', JSON.stringify(err));
      return;
    }

    AppDatabase.getInstance()
      .initialize(this.context)
      .then((): void => {
        const notificationService = new NotificationService();
        notificationService.registerPlanReminder();
        windowStage.loadContent('app/App', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'EntryAbility', 'Failed to load content. %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(DOMAIN, 'EntryAbility', 'Succeeded in loading content.');
        });
      })
      .catch((err: Error): void => {
        hilog.error(DOMAIN, 'EntryAbility', 'Failed to initialize database. %{public}s', JSON.stringify(err));
      });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onWindowStageDestroy');
    StatusBarService.unbindMainWindow();
    AppDatabase.getInstance().close();
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    try {
      useAppState().focusEngine.enterForeground();
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', 'Failed to call enterForeground: %{public}s', JSON.stringify(e));
    }
  }

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
