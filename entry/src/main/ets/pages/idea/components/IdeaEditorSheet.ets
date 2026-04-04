import { AppState } from '../../../app/AppStates';

/**
 * 闪记新建/编辑半屏页骨架。
 * TODO: 后续承载标题、正文和自动保存编辑能力。
 */
@ComponentV2
export struct IdeaEditorSheet {
  @Consumer('appState') appState: AppState = new AppState();

  build() {
    Column({ space: 8 }) {
      Text('IdeaEditorSheet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 承载闪记创建与详情编辑。')
        .fontSize(12)
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(20)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(this.appState.theme.palette.surface);
  }
}
