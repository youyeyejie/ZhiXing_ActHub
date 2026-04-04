import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 闪记热力图骨架。
 * TODO: 后续根据每日创建数量映射颜色深浅。
 */
@ComponentV2
export struct ActivityHeatmap {
  @Local private app: AppState = useAppState();

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
