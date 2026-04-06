import { AppState, useAppState } from '../../app/AppStates';

/**
 * 页面滚动布局容器。
 * 统一承接主页面的顶部起排、滚动区域和内容边距。
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
      });
    }
    .width('100%')
    .backgroundColor(this.app.theme.palette.background)
  }
}
