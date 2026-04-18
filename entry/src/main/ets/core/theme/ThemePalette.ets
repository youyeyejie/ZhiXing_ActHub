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
  info: string = '#3B82F6';
  infoSurface: string = '#EFF6FF';
  warning: string = '#F59E0B';
  warningSurface: string = '#FFF8E8';
  danger: string = '#EF4444';
  dangerSurface: string = '#FFE9E8';
  accentBlue: string = '#3B82F6';
  accentViolet: string = '#f455f7';
  accentGreen: string = '#22C55E';
  accentAmber: string = '#F59E0B';
  accentRed: string = '#EF4444';
  accentCyan: string = '#06B6D4';
  accentPurple: string = '#6127c4';
  accentEmerald: string = '#1aa174';
  background: string = '#F7F8FA';
  surface: string = '#FFFFFF';
  surfaceSecondary: string = '#F3F4F6';
  textPrimary: string = '#111111';
  textSecondary: string = '#667085';
  textTertiary: string = '#98A2B3';
  border: string = '#E5E7EB';
  transparent: string = '#00000000';
  mask: string = '#66000000';
  primaryShadowStrong: string = '#60004C24';
  primaryShadowSoft: string = '#40004C24';
  heatmapLevel_1: string = '#C6E5C8';
  heatmapLevel_2: string = '#7BC99A';
  heatmapLevel_3: string = '#4CAF7A';
  heatmapLevel_4: string = '#2E6B4A';
  heatmapLevel_5: string = '#1E4A2D';
  logo: string = "app.media.foreground_white";

  static light(): ThemePalette {
    const palette = new ThemePalette();
    palette.primary = '#004c24';
    palette.info = '#3B82F6';
    palette.infoSurface = '#EFF6FF';
    palette.warning = '#F59E0B';
    palette.warningSurface = '#FFF8E8';
    palette.danger = '#EF4444';
    palette.dangerSurface = '#FFE9E8';
    palette.accentBlue = '#3B82F6';
    palette.accentViolet = '#f455f7';
    palette.accentGreen = '#22C55E';
    palette.accentAmber = '#F59E0B';
    palette.accentRed = '#EF4444';
    palette.accentCyan = '#06B6D4';
    palette.accentPurple = '#6127c4';
    palette.accentEmerald = '#1aa174';
    palette.background = '#F7F8FA';
    palette.surface = '#FFFFFF';
    palette.surfaceSecondary = '#F3F4F6';
    palette.textPrimary = '#111111';
    palette.textSecondary = '#667085';
    palette.textTertiary = '#98A2B3';
    palette.border = '#E5E7EB';
    palette.transparent = '#00000000';
    palette.mask = '#66000000';
    palette.primaryShadowStrong = '#60004C24';
    palette.primaryShadowSoft = '#40004C24';
    palette.heatmapLevel_1 = '#C6E5C8';
    palette.heatmapLevel_2 = '#7BC99A';
    palette.heatmapLevel_3 = '#4CAF7A';
    palette.heatmapLevel_4 = '#2E6B4A';
    palette.heatmapLevel_5 = '#1E4A2D';
    palette.logo = "app.media.foreground_white";
    return palette;
  }

  static dark(): ThemePalette {
    const palette = new ThemePalette();
    palette.primary = '#a8ceb3';
    palette.info = '#60A5FA';
    palette.infoSurface = '#1E3A5F';
    palette.warning = '#FBBF24';
    palette.warningSurface = '#3D2D00';
    palette.danger = '#F87171';
    palette.dangerSurface = '#4A1D1D';
    palette.accentBlue = '#60A5FA';
    palette.accentViolet = '#e98bfa';
    palette.accentGreen = '#4de986';
    palette.accentAmber = '#FBBF24';
    palette.accentRed = '#F87171';
    palette.accentCyan = '#22D3EE';
    palette.accentPurple = '#ad6af0';
    palette.accentEmerald = '#52c79e';
    palette.background = '#0B1220';
    palette.surface = '#111827';
    palette.surfaceSecondary = '#1F2937';
    palette.textPrimary = '#F3F4F6';
    palette.textSecondary = '#CBD5E1';
    palette.textTertiary = '#94A3B8';
    palette.border = '#334155';
    palette.transparent = '#00000000';
    palette.mask = '#99000000';
    palette.primaryShadowStrong = '#60A8CEB3';
    palette.primaryShadowSoft = '#40A8CEB3';
    palette.heatmapLevel_1 = '#1E4A2D';
    palette.heatmapLevel_2 = '#2E6B4A';
    palette.heatmapLevel_3 = '#4CAF7A';
    palette.heatmapLevel_4 = '#7BC99A';
    palette.heatmapLevel_5 = '#C6E5C8';
    palette.logo = "app.media.foreground"
    return palette;
  }
}
