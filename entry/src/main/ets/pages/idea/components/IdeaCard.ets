import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 闪记列表卡片占位组件。
 * - TODO: 尚未接入标题、省略正文、创建时间和详情展开交互。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染闪记卡片占位内容。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct IdeaCard {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('IdeaCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 展示标题、正文摘要和时间信息。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
