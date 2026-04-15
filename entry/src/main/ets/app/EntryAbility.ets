import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppDatabase } from '../core/database/AppDatabase';
import { UserDatabase } from '../core/database/UserDatabase';
import { AppSettingRepository } from '../core/repositories/AppSettingRepository';
import { UserPreferenceRepository } from '../core/repositories/UserPreferenceRepository';
import { UserRepository } from '../core/repositories/UserRepository';
import { StatusBarService } from '../core/services/StatusBarService';
import { ThemeMode } from '../core/theme/ThemeManager';
import { useAppState } from './AppStates';
import { AppPreferenceKey } from './AppConstants';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private app = useAppState();

  private isSystemDarkMode(colorMode: ConfigurationConstant.ColorMode | undefined): boolean {
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
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

  private syncTheme(colorMode: ConfigurationConstant.ColorMode | undefined): void {
    const inMemoryValue: Object | undefined = AppStorage.get(AppPreferenceKey.PREFERRED_THEME_MODE);
    const mode: ThemeMode = typeof inMemoryValue === 'string'
      ? this.normalizeThemeMode(inMemoryValue)
      : ThemeMode.SYSTEM;
    this.app.applyThemePreference(mode, this.isSystemDarkMode(colorMode));
  }

  private async resolveLaunchThemeMode(): Promise<ThemeMode> {
    try {
      const settings: AppSettingRepository = new AppSettingRepository();
      const loggedIn: boolean = await settings.getBoolean('session.logged_in', false);
      const username: string = await settings.getString('session.username', '');
      if (!loggedIn || username.trim().length === 0) {
        hilog.info(DOMAIN, 'EntryAbility', 'resolveLaunchThemeMode no valid session');
        return ThemeMode.SYSTEM;
      }
      hilog.info(DOMAIN, 'EntryAbility', 'resolveLaunchThemeMode username=%{public}s', username);

      const user = await new UserRepository().findByAccount(username);
      if (user === null) {
        hilog.info(DOMAIN, 'EntryAbility', 'resolveLaunchThemeMode user missing');
        return ThemeMode.SYSTEM;
      }

      await UserDatabase.getInstance().initialize(this.context, user.name);
      const mode: string = await new UserPreferenceRepository().getString(
        AppPreferenceKey.PREFERRED_THEME_MODE,
        ThemeMode.SYSTEM,
      );
      hilog.info(DOMAIN, 'EntryAbility', 'resolveLaunchThemeMode user=%{public}s mode=%{public}s',
        user.name, mode);
      return this.normalizeThemeMode(mode);
    } catch (_error) {
      hilog.info(DOMAIN, 'EntryAbility', 'resolveLaunchThemeMode exception');
      return ThemeMode.SYSTEM;
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      hilog.info(DOMAIN, 'EntryAbility', 'Set color mode to COLOR_MODE_NOT_SET');
    } catch (err) {
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to set color mode. %{public}s', JSON.stringify(err));
    }

    AppStorage.setOrCreate(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
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
      .then(async (): Promise<void> => {
        const preferredThemeMode: ThemeMode = await this.resolveLaunchThemeMode();
        hilog.info(DOMAIN, 'EntryAbility', 'windowStageCreate resolved launch theme=%{public}s', preferredThemeMode);
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, preferredThemeMode);
        this.syncTheme(this.context.config.colorMode);
        windowStage.loadContent('app/App', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'EntryAbility', 'Failed to load content. %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(DOMAIN, 'EntryAbility', 'Succeeded in loading content.');
          this.app.tryRequestNotificationPermissionOnLaunch(this.context).catch((requestError: Error) => {
            hilog.error(
              DOMAIN,
              'EntryAbility',
              'Failed to request notification permission on launch. %{public}s',
              JSON.stringify(requestError),
            );
          });
        });
      })
      .catch((err: Error): void => {
        hilog.error(DOMAIN, 'EntryAbility', 'Failed to initialize database. %{public}s', JSON.stringify(err));
      });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onWindowStageDestroy');
    StatusBarService.unbindMainWindow();
    UserDatabase.getInstance().close();
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
