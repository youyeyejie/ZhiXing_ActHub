import display from '@ohos.display';

/**
 * 类功能简介：
 * - 安全区工具类，按设备宽高比提供顶部/底部建议内边距。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回顶部、底部和搜索页顶部建议内边距值。
 *
 * 副作用：
 * - 会调用显示服务读取屏幕尺寸信息。
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
