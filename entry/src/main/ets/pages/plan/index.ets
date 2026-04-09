import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { EditableSuite } from '../../components/form/EditableSuite';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口和详情弹层。
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
      actionIcon: $r('sys.symbol.magnifyingglass'),
      showFloatButton: true,
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('plan', '搜索日程'));
      },
      onClickFloatingButton: () => {
        this.app.nav.openActionSheet(this.buildPlanActionSheetContent);
      }
    }) {
      Text("此页面目前组件均为测试，需要修改！")
      WeekCalendar();

      PageScrollLayout({
        paddingBottom: 96
      }) {
      Row({ space: 10 }) {
        Button('测试 DetailCard')
          .height(36)
          .onClick(() => {
            this.app.nav.openDetailCard(this.buildPlanDetailCardContent);
          });
      }
        TimelineView();
        PlanCard();
        PlanCard();
        PlanCard();
        PlanCard();
        PlanCard();
        PlanEditorSheet();
      }
    }
  }
}
