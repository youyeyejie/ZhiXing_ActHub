import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 页面滚动布局容器，统一滚动区域间距和内边距配置。
 *
 * 可传入项：
 * - @Param space: 子元素垂直间距。
 * - @Param paddingTop/paddingRight/paddingBottom/paddingLeft: 四周内边距。
 * - @BuilderParam content: 滚动区域主体内容。
 *
 * 返回行为：
 * - 返回垂直可滚动的页面内容容器。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct PageScrollLayout {
  @Local private app: AppState = useAppState();
  @Param space: number = 16;
  @Param paddingTop: number = 20;
  @Param paddingRight: number = 20;
  @Param paddingBottom: number = 20;
  @Param paddingLeft: number = 20;
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {}

  build() {
    Scroll() {
      Column({ space: this.space }) {
        this.content();
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .padding({
        top: this.paddingTop,
        right: this.paddingRight,
        bottom: this.paddingBottom,
        left: this.paddingLeft
      })
      .constraintSize({
        minHeight: '100%'
      });
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
    .width('100%')
    .backgroundColor(this.app.theme.palette.background)
  }
}
