import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 闪记编辑半屏占位组件。
 * - TODO: 尚未接入标题、正文与自动保存流程。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染闪记编辑占位容器。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct IdeaEditorSheet {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('IdeaEditorSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载闪记创建与详情编辑。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(this.app.theme.palette.surface);
  }
}
