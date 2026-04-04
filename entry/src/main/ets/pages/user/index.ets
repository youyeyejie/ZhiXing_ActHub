import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';
import { CircleButton } from '../../components/buttons/CircleButton';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 我的页面骨架。
 * TODO: 后续接入用户信息、主题切换和统计信息汇总。
 */
@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();
  @Local private topInset: number = 56;

  private searchDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildSearchDialog,
    customStyle: true,
    autoCancel: false,
    alignment: DialogAlignment.Top
  });

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getSearchTopInset();
  }

  @Builder
  private buildSearchDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.app.theme.palette.background);

      SearchOverlay({
        title: '用户搜索',
        placeholder: '搜索用户名称',
        scope: SearchScope.User,
        topInset: this.topInset,
        onDismiss: () => {
          this.searchDialogController.close();
        }
      });
    }
    .width('100%')
    .height('100%');
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
