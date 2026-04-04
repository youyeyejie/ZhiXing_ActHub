import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';

/**
 * 我的页面骨架。
 * TODO: 后续接入用户信息、主题切换和统计信息汇总。
 */
@ComponentV2
export struct UserPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('我的')
          .fontSize(28)
          .fontWeight(FontWeight.Bold);
        Text('TODO: 用户信息区与主题切换入口。')
          .fontSize(14)
          .fontColor('#666666');
        FocusStatsChart();
        ActivityHeatmap();
        SettingsPanel();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
