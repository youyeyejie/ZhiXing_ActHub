/**
 * 类功能简介：
 * - 一言服务占位类，预留随机文案获取接口。
 * - TODO: 尚未接入网络接口与本地回退句库。
 *
 * 可传入项：
 * - 无（当前方法无参数）。
 *
 * 返回行为：
 * - `fetchSentence` 返回字符串 Promise 占位。
 *
 * 副作用：
 * - 当前无实际副作用。
 */
export class HitokotoService {
  fetchSentence(): Promise<string> {
    // TODO: 获取一句推荐文案。
    return Promise.resolve('');
  }
}
