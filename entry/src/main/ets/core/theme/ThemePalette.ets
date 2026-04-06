/**
 * 主题调色板定义。
 * 提供浅色/深色语义色配置。
 */
export class ThemePalette {
  primary: string = '#4A7AFF';
  background: string = '#F7F8FA';
  surface: string = '#FFFFFF';
  surfaceSecondary: string = '#F3F4F6';
  textPrimary: string = '#111111';
  textSecondary: string = '#667085';
  textTertiary: string = '#98A2B3';
  border: string = '#E5E7EB';
  mask: string = '#66000000';
  searchOverlayMask: string = '#73070A0F';

  static light(): ThemePalette {
    const palette = new ThemePalette();
    palette.primary = '#2563EB';
    palette.background = '#F7F8FA';
    palette.surface = '#FFFFFF';
    palette.surfaceSecondary = '#F3F4F6';
    palette.textPrimary = '#111111';
    palette.textSecondary = '#667085';
    palette.textTertiary = '#98A2B3';
    palette.border = '#E5E7EB';
    palette.mask = '#66000000';
    palette.searchOverlayMask = '#73070A0F';
    return palette;
  }

  static dark(): ThemePalette {
    const palette = new ThemePalette();
    palette.primary = '#60A5FA';
    palette.background = '#0B1220';
    palette.surface = '#111827';
    palette.surfaceSecondary = '#1F2937';
    palette.textPrimary = '#F3F4F6';
    palette.textSecondary = '#CBD5E1';
    palette.textTertiary = '#94A3B8';
    palette.border = '#334155';
    palette.mask = '#99000000';
    palette.searchOverlayMask = '#800A0D12';
    return palette;
  }
}
