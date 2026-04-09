import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 待办分类筛选占位组件。
 * - TODO: 尚未接入分类数据源、选中态与筛选回调。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染分类筛选占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct CategoryFilter {
  @Local private app: AppState = useAppState();

  /**
   * 渲染分类筛选占位。
   * TODO: 后续接入分类列表、选中态和筛选回调。
   */
  build() {
    Column({ space: 8 }) {
      Text('CategoryFilter')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 按分类筛选待办列表。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
