import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { EditableSuite } from '../../components/form/EditableSuite';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口、浮动新建按钮和详情弹层。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();

  @Builder
  private buildPlanActionSheetContent() {
    Column({ space: 12 }) {
      Text('日程 ActionSheet 测试')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);

      EditableSuite({
        title: '日程动作编辑套件'
      });

      Button('关闭 ActionSheet')
        .width('100%')
        .height(42)
        .onClick(() => {
          this.app.nav.back(false);
        });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private buildPlanDetailCardContent() {
    Column({ space: 8 }) {
      Text('日程 DetailCard 测试')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Text('通过 AppNav 调用时已传入完整自定义 Builder 内容。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    MainTabPageLayout({
      title: '日程',
      actionIcon: $r('sys.media.ohos_ic_public_search_filled'),
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('plan', '搜索日程'));
      }
    }) {
      Row({ space: 10 }) {
        Button('测试 ActionSheet')
          .height(36)
          .onClick(() => {
            this.app.nav.openActionSheet(this.buildPlanActionSheetContent);
          });

      Button('测试 DetailCard')
        .height(36)
        .onClick(() => {
          this.app.nav.openDetailCard(this.buildPlanDetailCardContent);
        });
      }

      WeekCalendar();
      TimelineView();
      PlanCard();
      PlanEditorSheet();
    }
  }
}
