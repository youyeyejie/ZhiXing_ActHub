import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

export class HashUtils {
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

  private static bytesToHex(data: Uint8Array): string {
    let result: string = '';
    for (let index = 0; index < data.length; index++) {
      result += data[index].toString(16).padStart(2, '0');
    }
    return result;
  }
}
