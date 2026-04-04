import { ThemePalette } from './ThemePalette';

/**
 * 全局主题管理器。
 * 负责深浅色模式与调色板分发。
 */
export enum ThemeMode {
  LIGHT = 'LIGHT',
  DARK = 'DARK',
  SYSTEM = 'SYSTEM'
}

@ObservedV2
export class ThemeManager {
  @Trace private _mode: ThemeMode = ThemeMode.LIGHT;
  @Trace private _systemDark: boolean = false;

  set(mode: ThemeMode): void {
    this._mode = mode;
  }

  setSystemDark(isDark: boolean): void {
    this._systemDark = isDark;
  }

  get(): ThemeMode {
    return this._mode;
  }

  @Computed
  get isDark(): boolean {
    if (this._mode === ThemeMode.DARK) {
      return true;
    }
    if (this._mode === ThemeMode.LIGHT) {
      return false;
    }
    return this._systemDark;
  }

  @Computed
  get palette(): ThemePalette {
    return this.isDark ? ThemePalette.dark() : ThemePalette.light();
  }
}
