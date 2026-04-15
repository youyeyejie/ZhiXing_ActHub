import { AppState, useAppState } from '../../app/AppStates';
import { DetailCard, DetailCardController } from '../card/DetailCard';

/**
 * 组件功能简介：
 * - DetailCard overlay 路由容器，负责在目的页中挂载 DetailCard 组件。
 *
 * 可传入项：
 * - @BuilderParam content: 透传给 DetailCard 的内容 Builder。
 *
 * 返回行为：
 * - 返回对话式目的页容器并渲染 DetailCard。
 *
 * 副作用：
 * - 关闭事件与返回键会触发导航返回。
 */
@ComponentV2
export struct DetailCardOverlayDestination {
  @Local private app: AppState = useAppState();
  private detailCardController: DetailCardController = new DetailCardController();
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {}

  build() {
    NavDestination() {
      DetailCard({
        controller: this.detailCardController,
        cardHeight: this.app.nav.detailCardHeight,
        onDismiss: () => {
          this.app.nav.back(false);
        }
      }) {
        this.content();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .mode(NavDestinationMode.DIALOG)
    .onBackPressed(() => {
      this.detailCardController.dismiss();
      return true;
    });
  }
}
