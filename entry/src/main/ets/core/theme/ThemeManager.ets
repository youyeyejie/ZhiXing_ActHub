import { ThemeMode } from '../../common/types/AppEnums';
import { ThemePalette } from './ThemePalette';

/**
 * 全局主题管理器占位。
 * TODO: 后续接入深浅色切换、系统主题跟随和主题注入能力。
 */
export class ThemeManager {
  private mode: ThemeMode = ThemeMode.SYSTEM;
  private palette: ThemePalette = new ThemePalette();

  setMode(mode: ThemeMode): void {
    // TODO: 切换主题模式并触发全局刷新。
    this.mode = mode;
  }

  getMode(): ThemeMode {
    return this.mode;
  }

  getPalette(): ThemePalette {
    return this.palette;
  }
}
