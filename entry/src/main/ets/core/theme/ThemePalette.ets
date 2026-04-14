/**
 * 类功能简介：
 * - 主题调色板模型，提供浅色与深色语义色方案。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 通过 `light()` 与 `dark()` 返回对应调色板实例。
 *
 * 副作用：
 * - 无副作用。
 */
export class ThemePalette {
  primary: string = '#004c24';
  background: string = '#F7F8FA';
  surface: string = '#FFFFFF';
  surfaceSecondary: string = '#F3F4F6';
  textPrimary: string = '#111111';
  textSecondary: string = '#667085';
  textTertiary: string = '#98A2B3';
  border: string = '#E5E7EB';
  mask: string = '#66000000';
  logo: string = "app.media.foreground_white";

  static light(): ThemePalette {
    const palette = new ThemePalette();
    palette.primary = '#004c24';
    palette.background = '#F7F8FA';
    palette.surface = '#FFFFFF';
    palette.surfaceSecondary = '#F3F4F6';
    palette.textPrimary = '#111111';
    palette.textSecondary = '#667085';
    palette.textTertiary = '#98A2B3';
    palette.border = '#E5E7EB';
    palette.mask = '#66000000';
    palette.logo = "app.media.foreground_white";
    return palette;
  }

  static dark(): ThemePalette {
    const palette = new ThemePalette();
    palette.primary = '#a8ceb3';
    palette.background = '#0B1220';
    palette.surface = '#111827';
    palette.surfaceSecondary = '#1F2937';
    palette.textPrimary = '#F3F4F6';
    palette.textSecondary = '#CBD5E1';
    palette.textTertiary = '#94A3B8';
    palette.border = '#334155';
    palette.mask = '#99000000';
    palette.logo = "app.media.foreground"
    return palette;
  }
}
