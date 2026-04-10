import { http } from '@kit.NetworkKit';

/**
 * 一言服务。
 * 提供随机句子获取，支持网络请求和本地回退。
 */
export class HitokotoService {
  // 本地备用句库
  private static readonly FALLBACK_SENTENCES: string[] = [
    '生活不是等待风暴过去，而是学会在雨中跳舞。',
    '每一个不曾起舞的日子，都是对生命的辜负。',
    '别让焦虑消耗你的未来，活在当下才是最好的选择。',
    '世界上只有一种真正的英雄主义，那就是认清生活的真相后依然热爱生活。',
    '你要做一个不动声色的大人了，不准情绪化，不准偷偷想念，不准回头看。',
    '人生没有白走的路，每一步都算数。',
    '保持热爱，奔赴山海。',
    '愿你历尽千帆，归来仍是少年。',
    '时间会证明一切，耐心是最珍贵的品质。',
    '生活明朗，万物可爱，人间值得，未来可期。'
  ];

  /**
   * 获取一言句子。
   * 优先请求网络接口，失败时回退到本地句库。
   * @returns 一句推荐文案
   */
  async fetchSentence(): Promise<string> {
    try {
      const response = await this.requestFromApi();
      if (response && response.length > 0) {
        return response;
      }
    } catch (_error) {
      // 网络失败，使用本地句库
    }
    return this.getRandomFallback();
  }

  /**
   * 从一言 API 获取句子。
   */
  private async requestFromApi(): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const result = await httpRequest.request('https://v1.hitokoto.cn/', {
        method: http.RequestMethod.GET,
        connectTimeout: 3000,
        readTimeout: 3000
      });
      if (result.responseCode === 200 && result.result) {
        const data: Record<string, string> = JSON.parse(result.result as string);
        if (data.hitokoto) {
          return data.hitokoto;
        }
      }
    } catch (_error) {
      // 忽略错误
    } finally {
      httpRequest.destroy();
    }
    return '';
  }

  /**
   * 从本地句库获取随机句子。
   */
  private getRandomFallback(): string {
    const sentences = HitokotoService.FALLBACK_SENTENCES;
    const index = Math.floor(Math.random() * sentences.length);
    return sentences[index];
  }
}
