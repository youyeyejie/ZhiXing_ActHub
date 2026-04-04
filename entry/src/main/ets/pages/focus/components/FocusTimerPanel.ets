import { CircularProgress } from '../../../components/progress/CircularProgress';

/**
 * 专注计时面板骨架。
 * TODO: 后续接入番茄钟状态机、开始暂停和休息阶段控制。
 */
@ComponentV2
export struct FocusTimerPanel {
  build() {
    Column({ space: 16 }) {
      Text('FocusTimerPanel')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      CircularProgress();
      Text('TODO: 展示倒计时与控制按钮。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor('#FFFFFF');
  }
}
