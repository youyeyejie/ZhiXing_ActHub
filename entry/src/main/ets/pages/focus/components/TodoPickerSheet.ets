import { AppState } from '../../../app/AppStates';

/**
 * 专注前待办选择骨架。
 * TODO: 后续以 ActionSheet 形式展示未完成待办列表。
 */
@ComponentV2
export struct TodoPickerSheet {
  @Consumer('appState') appState: AppState = new AppState();

  build() {
    Column({ space: 8 }) {
      Text('TodoPickerSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 选择一个待办关联当前专注。')
        .fontSize(12)
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(this.appState.theme.palette.surface);
  }
}
