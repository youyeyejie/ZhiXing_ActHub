import { AppState, useAppState } from '../../app/AppStates';
import { ActionSheet, ActionSheetController } from '../card/ActionSheet';

/**
 * 组件功能简介：
 * - ActionSheet overlay 路由容器，负责在目的页中挂载 ActionSheet 组件。
 *
 * 可传入项：
 * - @BuilderParam content: 透传给 ActionSheet 的内容 Builder。
 *
 * 返回行为：
 * - 返回对话式目的页容器并渲染 ActionSheet。
 *
 * 副作用：
 * - 关闭事件与返回键会触发导航返回。
 */
@ComponentV2
export struct ActionSheetOverlayDestination {
  @Local private app: AppState = useAppState();
  private actionSheetController: ActionSheetController = new ActionSheetController();
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {}

  build() {
    NavDestination() {
      ActionSheet({
        panelHeight: '56%',
        controller: this.actionSheetController,
        onDismiss: () => {
          this.app.nav.back(false);
        }
      }) {
        this.content();
      }
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .mode(NavDestinationMode.DIALOG)
    .onBackPressed(() => {
      this.actionSheetController.dismiss();
      return true;
    });
  }
}
