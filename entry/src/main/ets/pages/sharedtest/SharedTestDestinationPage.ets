import { AppState, useAppState } from '../../app/AppStates';
import { SafeAreaInsetLayout } from '../../components/layout/SafeAreaInsetLayout';
import { ActionSheetController } from '../../components/card/ActionSheet';
import { DetailCardController } from '../../components/card/DetailCard';
import { SharedInteractionTestPage } from '../sharedtest';

/**
 * 组件功能简介：
 * - 共享测试页的 NavDestination 容器，负责承载测试页面与浮层状态。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 返回全屏目的页容器并渲染 `SharedInteractionTestPage`。
 *
 * 副作用：
 * - `onBackPressed` 会优先关闭详情/动作弹层，再执行导航返回。
 */
@ComponentV2
export struct SharedTestDestinationPage {
  @Local private app: AppState = useAppState();
  @Local private actionSheetVisible: boolean = false;
  @Local private detailCardVisible: boolean = false;
  private actionSheetController: ActionSheetController = new ActionSheetController();
  private detailCardController: DetailCardController = new DetailCardController();

  build() {
    NavDestination() {
      SafeAreaInsetLayout({
        includeTop: true,
        surfaceColor: this.app.theme.palette.background
      }) {
        SharedInteractionTestPage({
          actionSheetVisible: this.actionSheetVisible,
          detailCardVisible: this.detailCardVisible,
          actionSheetController: this.actionSheetController,
          detailCardController: this.detailCardController,
          onOpenActionSheet: () => {
            this.actionSheetVisible = true;
          },
          onCloseActionSheet: () => {
            this.actionSheetVisible = false;
          },
          onOpenDetailCard: () => {
            this.detailCardVisible = true;
          },
          onCloseDetailCard: () => {
            this.detailCardVisible = false;
          }
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background)
    .onBackPressed(() => {
      if (this.detailCardVisible) {
        this.detailCardController.dismiss();
        return true;
      }
      if (this.actionSheetVisible) {
        this.actionSheetController.dismiss();
        return true;
      }
      this.app.nav.back();
      return true;
    });
  }
}

@Builder
export function SharedTestDestinationPageBuilder(_name: string, _param: Object) {
  SharedTestDestinationPage();
}
