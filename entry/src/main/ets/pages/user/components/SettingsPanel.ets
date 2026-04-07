import { AppState, useAppState } from '../../../app/AppStates';
import { ThemeMode } from '../../../core/theme/ThemeManager';

/**
 * 设置面板骨架。
 * TODO: 后续放入主题切换、提醒开关、导入导出和退出登录入口。
 */
@ComponentV2
export struct SettingsPanel {
  @Local private app: AppState = useAppState();
  @Local private preferredThemeMode: ThemeMode = ThemeMode.SYSTEM;

  private readSystemDarkMode(): boolean {
    const value: Object | undefined = AppStorage.get('systemDarkMode');
    return value === true;
  }

  aboutToAppear(): void {
    const value: Object | undefined = AppStorage.get('preferredThemeMode');
    if (value === ThemeMode.DARK) {
      this.preferredThemeMode = ThemeMode.DARK;
    } else if (value === ThemeMode.LIGHT) {
      this.preferredThemeMode = ThemeMode.LIGHT;
    } else {
      this.preferredThemeMode = ThemeMode.SYSTEM;
    }
    this.app.applyThemePreference(this.preferredThemeMode, this.readSystemDarkMode());
  }

  private selectTheme(mode: ThemeMode): void {
    this.preferredThemeMode = mode;
    AppStorage.set('preferredThemeMode', mode);
    this.app.applyThemePreference(mode, this.readSystemDarkMode());
  }

  private isActiveMode(mode: ThemeMode): boolean {
    return this.preferredThemeMode === mode;
  }

  @Builder
  private buildModeButton(label: string, mode: ThemeMode) {
    Button(label)
      .layoutWeight(1)
      .height(36)
      .fontSize(13)
      .fontWeight(this.isActiveMode(mode) ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.isActiveMode(mode) ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(this.isActiveMode(mode) ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .onClick(() => {
        this.selectTheme(mode);
      });
  }

  build() {
    Column({ space: 8 }) {
      Text('显示模式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Text('可选择跟随系统、深色或浅色模式。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);

      Row({ space: 8 }) {
        this.buildModeButton('跟随系统', ThemeMode.SYSTEM);
        this.buildModeButton('浅色', ThemeMode.LIGHT);
        this.buildModeButton('深色', ThemeMode.DARK);
      }
      .width('100%');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
