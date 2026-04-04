import display from '@ohos.display';

/**
 * 全面屏安全区工具。
 * 按屏幕长宽比给出顶部与底部建议内边距。
 */
export class SafeAreaUtils {
  static getTopInset(): number {
    const ratio = SafeAreaUtils.getAspectRatio();
    if (ratio >= 2.18) {
      return 48;
    }
    if (ratio >= 2.0) {
      return 40;
    }
    return 30;
  }

  static getBottomInset(): number {
    const ratio = SafeAreaUtils.getAspectRatio();
    if (ratio >= 2.18) {
      return 22;
    }
    if (ratio >= 2.0) {
      return 18;
    }
    return 12;
  }

  static getSearchTopInset(): number {
    return SafeAreaUtils.getTopInset() + 20;
  }

  private static getAspectRatio(): number {
    try {
      const info = display.getDefaultDisplaySync();
      const longEdge = Math.max(info.width, info.height);
      const shortEdge = Math.max(1, Math.min(info.width, info.height));
      return longEdge / shortEdge;
    } catch (_error) {
      return 2.0;
    }
  }
}
