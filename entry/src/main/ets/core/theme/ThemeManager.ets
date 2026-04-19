import { ThemePalette } from './ThemePalette';

/**
 * 组件功能简介：
 * - 主题模式枚举，定义浅色、深色与跟随系统三种模式。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 为主题管理器提供模式取值约束。
 *
 * 副作用：
 * - 无副作用。
 */
export enum ThemeMode {
  LIGHT = 'LIGHT',
  DARK = 'DARK',
  SYSTEM = 'SYSTEM'
}

/**
 * 组件功能简介：
 * - 全局主题管理器，负责主题模式切换与调色板计算。
 *
 * 可传入项：
 * - `set(mode)` 设置主题模式；`setSystemDark(isDark)` 设置系统深色状态。
 *
 * 返回行为：
 * - 提供当前模式、深色判定和调色板计算结果。
 *
 * 副作用：
 * - 会更新响应式主题状态并驱动界面重绘。
 */
@ObservedV2
export class ThemeManager {
  @Trace private _mode: ThemeMode = ThemeMode.SYSTEM;
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
