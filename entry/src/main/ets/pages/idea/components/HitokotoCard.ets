import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 一言展示卡片占位组件。
 * - TODO: 尚未接入网络文案拉取与本地句库回退策略。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染一言卡片占位内容。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct HitokotoCard {
  @Local private app: AppState = useAppState();

  /**
   * 渲染一言卡片占位。
   * TODO: 后续接入网络请求与本地句库兜底策略。
   */
  build() {
    Column({ space: 8 }) {
      Text('HitokotoCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示随机句子或本地回退文案。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
