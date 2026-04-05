import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';
import { CircleButton } from '../../components/buttons/CircleButton';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState } from '../../app/AppStates';
import { InteractableCard } from '../../components/card/InteractableCard';

/**
 * 我的页面骨架。
 * TODO: 后续接入用户信息、主题切换和统计信息汇总。
 */
@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();
  @Local private topInset: number = SafeAreaUtils.getSearchTopInset();

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getSearchTopInset();
  }

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
              this.app.nav.openSharedTest();
            }
          });
        }
        .width('100%');
        Text('TODO: 用户信息区与主题切换入口。')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary);
        InteractableCard({
          leftHint: '左滑: 删除',
          rightHint: '右滑: 启动专注',
          enableSwipeLeft: true,
          enableSwipeRight: false,
          onCardTap: () => {
            this.app.nav.openPlanDetail('shared-test-plan-001');
          }
          }) {
          Column({ space: 8 }) {
              Text('交互卡片手势测试')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.app.theme.palette.textPrimary);
              Text('左右滑动达到阈值后触发回调。')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }
          .alignItems(HorizontalAlign.Start);
          }
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
