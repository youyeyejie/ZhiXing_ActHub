import {
  AbilityConstant,
  Configuration,
  ConfigurationConstant,
  UIAbility,
  Want,
} from "@kit.AbilityKit";
import { window } from "@kit.ArkUI";
import { AppDatabase } from "../core/database/AppDatabase";
import { UserDatabase } from "../core/database/UserDatabase";
import { AppSettingRepository } from "../core/repositories/AppSettingRepository";
import { UserPreferenceRepository } from "../core/repositories/UserPreferenceRepository";
import { UserRepository } from "../core/repositories/UserRepository";
import { StatusBarService } from "../core/services/StatusBarService";
import { ThemeMode } from "../core/theme/ThemeManager";
import { useAppState } from "./AppStates";
import { AppPreferenceKey } from "./AppConstants";

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
    const mode: ThemeMode =
      typeof inMemoryValue === "string" ? this.normalizeThemeMode(inMemoryValue) : ThemeMode.SYSTEM;
    this.app.applyThemePreference(mode, this.isSystemDarkMode(colorMode));
  }

  private async resolveLaunchThemeMode(): Promise<ThemeMode> {
    try {
      const settings: AppSettingRepository = new AppSettingRepository();
      const loggedIn: boolean = await settings.getBoolean("session.logged_in", false);
      const username: string = await settings.getString("session.username", "");
      if (!loggedIn || username.trim().length === 0) {
        return ThemeMode.SYSTEM;
      }

      const user = await new UserRepository().findByAccount(username);
      if (user === null) {
        return ThemeMode.SYSTEM;
      }

      await UserDatabase.getInstance().initialize(this.context, user.name);
      const mode: string = await new UserPreferenceRepository().getString(
        AppPreferenceKey.PREFERRED_THEME_MODE,
        ThemeMode.SYSTEM,
      );
      return this.normalizeThemeMode(mode);
    } catch (_error) {
      return ThemeMode.SYSTEM;
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context
        .getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (_err) {}

    AppStorage.setOrCreate(AppPreferenceKey.PREFERRED_THEME_MODE, ThemeMode.SYSTEM);
    AppStorage.setOrCreate("currentColorMode", this.context.config.colorMode);
    AppStorage.setOrCreate("systemDarkMode", this.isSystemDarkMode(this.context.config.colorMode));
    this.syncTheme(this.context.config.colorMode);
    this.app.enterSplash();
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.set("currentColorMode", newConfig.colorMode);
    AppStorage.set("systemDarkMode", this.isSystemDarkMode(newConfig.colorMode));
    this.syncTheme(newConfig.colorMode);
  }

  onDestroy(): void {}

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      StatusBarService.bindMainWindow(mainWindow);
      mainWindow.setWindowLayoutFullScreen(true);
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: this.app.theme.palette.transparent,
        navigationBarColor: this.app.theme.palette.transparent,
        statusBarContentColor: this.app.theme.palette.textPrimary,
        navigationBarContentColor: this.app.theme.palette.textPrimary,
      });
    } catch (_err) {
      return;
    }

    AppDatabase.getInstance()
      .initialize(this.context)
      .then(async (): Promise<void> => {
        const preferredThemeMode: ThemeMode = await this.resolveLaunchThemeMode();
        AppStorage.set(AppPreferenceKey.PREFERRED_THEME_MODE, preferredThemeMode);
        this.syncTheme(this.context.config.colorMode);

        windowStage.loadContent("app/App", (err) => {
          if (err.code) {
            return;
          }
          this.app
            .tryRequestNotificationPermissionOnLaunch(this.context)
            .catch((_requestError: Error) => {});
          this.app
            .tryRequestCalendarPermissionOnLaunch(this.context)
            .catch((_requestError: Error) => {});
        });
      })
      .catch((_err: Error): void => {});
  }

  onWindowStageDestroy(): void {
    StatusBarService.unbindMainWindow();
    UserDatabase.getInstance().close();
    AppDatabase.getInstance().close();
  }

  onForeground(): void {
    // Ability has brought to foreground
    try {
      useAppState().focusEngine.enterForeground();
    } catch (_e) {}
  }

  onBackground(): void {
    // Ability has back to background
    try {
      useAppState().focusEngine.enterBackground();
    } catch (_e) {}
  }
}
