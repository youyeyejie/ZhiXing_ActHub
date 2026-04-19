import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

/**
 * 组件功能简介：
 * - 哈希工具类，提供字符串到 MD5 十六进制摘要转换。
 *
 * 可传入项：
 * - `md5Hex(value)` 的 `value` 为待哈希字符串。
 *
 * 返回行为：
 * - 成功返回 MD5 十六进制字符串，失败返回空字符串。
 *
 * 副作用：
 * - 会调用系统加密框架执行摘要计算。
 */
export class HashUtils {
  /**
   * 组件功能简介：
   * - 计算字符串 MD5 摘要。
   *
   * 可传入项：
   * - `value`: 待计算的原始字符串。
   *
   * 返回行为：
   * - 返回 MD5 十六进制字符串；异常时返回空字符串。
   *
   * 副作用：
   * - 会分配临时字节数组并调用底层加密实现。
   */
  static async md5Hex(value: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('MD5');
      await md.update({
        data: new Uint8Array(buffer.from(value, 'utf-8').buffer)
      });
      const digest = await md.digest();
      return HashUtils.bytesToHex(digest.data);
    } catch (_error) {
      return '';
    }
  }

  /**
   * 组件功能简介：
   * - 将字节数组转为十六进制字符串。
   *
   * 可传入项：
   * - `data`: 需要转换的字节数组。
   *
   * 返回行为：
   * - 返回对应十六进制编码结果。
   *
   * 副作用：
   * - 无。
   */
  private static bytesToHex(data: Uint8Array): string {
    let result: string = '';
    for (let index = 0; index < data.length; index++) {
      result += data[index].toString(16).padStart(2, '0');
    }
    return result;
  }
}
