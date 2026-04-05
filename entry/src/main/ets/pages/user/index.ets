import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';
import { CircleButton } from '../../components/buttons/CircleButton';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 我的页面骨架。
 * TODO: 后续接入用户信息、主题切换和统计信息汇总。
 */
@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Text('我的')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1);

          CircleButton({
            icon: '!',
            text: '测试',
            buttonSize: 46,
            fillColor: this.app.theme.palette.primary,
            onTap: () => {
              this.app.nav.pushOverlayByName(AppOverlayRoute.SHARED_TEST);
            }
          });
        }
        .width('100%');
        Text('TODO: 用户信息区与主题切换入口。')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary);
        FocusStatsChart();
        ActivityHeatmap();
        SettingsPanel();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
