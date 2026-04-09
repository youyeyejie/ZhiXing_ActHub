import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 内容流容器占位组件，预留列表懒加载与分页能力。
 * - TODO: 尚未接入数据源、分页策略和统一间距规则。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染内容流占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct ContentFlow {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('ContentFlow')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载页面内容列表与懒加载逻辑。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
