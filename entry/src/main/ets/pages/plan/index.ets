import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { ActionSheet, ActionSheetController } from '../../components/card/ActionSheet';
import { DetailCard, DetailCardController } from '../../components/card/DetailCard';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';
import { EditableSuite } from '../../components/form/EditableSuite';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口、浮动新建按钮和详情弹层。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();
  @Local private actionSheetVisible: boolean = false;
  @Local private detailCardVisible: boolean = false;
  private actionSheetController: ActionSheetController = new ActionSheetController();
  private detailCardController: DetailCardController = new DetailCardController();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  private syncBottomBarVisibility(): void {
    const hasOverlay: boolean = this.actionSheetVisible || this.detailCardVisible;
    this.onBottomBarVisibleChange(!hasOverlay);
  }

  aboutToAppear(): void {
    this.syncBottomBarVisibility();
  }

  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  @Builder
  private buildActionSheetContent() {
    Column({ space: 12 }) {
      Text('ActionSheet 内容测试')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);

      EditableSuite({
        title: '动作编辑套件'
      });

      Button('关闭弹层')
        .width('100%')
        .height(42)
        .onClick(() => {
          this.actionSheetController.dismiss();
        });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private buildDetailCardContent() {
    Column({ space: 8 }) {
      Text('Plan DetailCard 测试')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Text('用于验证详情卡片动画、遮罩点击与返回键关闭。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      MainTabPageLayout({
        title: '日程',
        actionIcon: '?',
        actionText: '搜索',
        actionFillColor: this.app.theme.palette.primary,
        onActionTap: () => {
          this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('plan', '搜索日程'));
        }
      }) {
        Row({ space: 10 }) {
          Button('测试 ActionSheet')
            .height(36)
            .onClick(() => {
              this.actionSheetVisible = true;
              this.syncBottomBarVisibility();
            });

          Button('测试 DetailCard')
            .height(36)
            .onClick(() => {
              this.detailCardVisible = true;
              this.syncBottomBarVisibility();
            });
        }
        .width('100%');

        WeekCalendar();
        TimelineView();
        PlanCard();
        PlanEditorSheet();
      }

      if (this.actionSheetVisible) {
        ActionSheet({
          isVisible: this.actionSheetVisible,
          panelHeight: '56%',
          controller: this.actionSheetController,
          onDismiss: () => {
            this.actionSheetVisible = false;
            this.syncBottomBarVisibility();
          }
        }) {
          this.buildActionSheetContent();
        }
      }

      if (this.detailCardVisible) {
        DetailCard({
          isVisible: this.detailCardVisible,
          controller: this.detailCardController,
          onDismiss: () => {
            this.detailCardVisible = false;
            this.syncBottomBarVisibility();
          }
        }) {
          this.buildDetailCardContent();
        }
      }
    }
    .width('100%')
    .height('100%');
  }
}
