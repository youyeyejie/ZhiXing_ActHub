import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 闪记活跃热力图占位组件。
 * - TODO: 尚未接入按日统计与颜色映射策略。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染热力图占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct ActivityHeatmap {
  @Local private app: AppState = useAppState();

  /**
   * 渲染活跃度热力图占位。
   * TODO: 后续接入日期维度统计数据和色阶映射。
   */
  build() {
    Column({ space: 8 }) {
      Text('ActivityHeatmap')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示笔记活跃度统计。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
