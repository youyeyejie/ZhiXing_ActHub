import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 组件功能简介：
 * - 专注前待办选择占位组件。
 * - TODO: 尚未接入未完成待办列表与选择确认流程。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 渲染待办选择占位卡片。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct TodoPickerSheet {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('TodoPickerSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 选择一个待办关联当前专注。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(this.app.theme.palette.surface);
  }
}
