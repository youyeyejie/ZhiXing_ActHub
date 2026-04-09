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
 * 组件功能简介：
 * - 日程模块主页，承载周历、时间轴、卡片与编辑入口测试骨架。
 * - TODO: 尚未接入真实日程数据、搜索联动和详情流。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回主标签页布局，内含日程相关测试组件与操作入口。
 *
 * 副作用：
 * - 按钮事件会调用 AppNav 打开搜索、ActionSheet 与 DetailCard overlay。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();

  @Builder
  /**
   * 构建日程 ActionSheet 的测试内容。
   * TODO: 后续替换为真实日程编辑表单。
   */
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
  /**
   * 构建日程 DetailCard 的测试内容。
   * TODO: 后续接入真实日程详情展示与编辑入口。
   */
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

  /**
   * 渲染日程主页骨架与测试交互入口。
   */
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
