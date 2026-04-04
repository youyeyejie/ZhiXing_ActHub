import { ThemePalette } from './ThemePalette';

/**
 * 全局主题管理器占位。
 * TODO: 后续接入深浅色切换、系统主题跟随和主题注入能力。
 */


export enum ThemeMode {
  LIGHT = 'LIGHT',
  DARK = 'DARK',
  SYSTEM = 'SYSTEM'
}


@ObservedV2
export class ThemeManager {
  @Trace private _mode: ThemeMode = ThemeMode.SYSTEM;

  set(mode: ThemeMode) {
    this._mode = mode;
  }

  get(): ThemeMode {
    return this._mode;
  }

  @Computed
  get palette() {
    // TODO: multiple palette
    return new ThemePalette();
  }
}
