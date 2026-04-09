import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 待办编辑半屏占位组件。
 * - TODO: 尚未接入真实待办字段、分类选择和保存流程。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染半屏占位编辑容器。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct TodoEditorSheet {
  @Local private app: AppState = useAppState();

  /**
   * 渲染待办编辑半屏占位。
   * TODO: 后续接入真实待办编辑字段和保存逻辑。
   */
  build() {
    Column({ space: 8 }) {
      Text('TodoEditorSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载待办创建与详情编辑。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(this.app.theme.palette.surface);
  }
}
