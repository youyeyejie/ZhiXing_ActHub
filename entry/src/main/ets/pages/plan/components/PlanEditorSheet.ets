import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 日程编辑半屏页占位组件。
 * - TODO: 尚未接入真实表单字段、校验与保存。
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
export struct PlanEditorSheet {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('PlanEditorSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载日程字段编辑表单。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(this.app.theme.palette.surface);
  }
}
