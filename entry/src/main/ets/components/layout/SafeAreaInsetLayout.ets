import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';

/**
 * 统一安全区内边距容器。
 * 将顶部/底部安全区和额外偏移收敛为可复用布局组件。
 */
@ComponentV2
export struct SafeAreaInsetLayout {
  @Param includeTop: boolean = false;
  @Param includeBottom: boolean = false;
  @Param extraTop: number = 0;
  @Param extraBottom: number = 0;
  @Param fillHeight: boolean = true;
  @Param surfaceColor: ResourceColor = Color.Transparent;
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  private emptyContent() {}

  private resolveTopPadding(): number {
    if (!this.includeTop) {
      return this.extraTop;
    }
    return SafeAreaUtils.getTopInset() + this.extraTop;
  }

  private resolveBottomPadding(): number {
    if (!this.includeBottom) {
      return this.extraBottom;
    }
    return SafeAreaUtils.getBottomInset() + this.extraBottom;
  }

  build() {
   Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.content();
      }
      .width('100%')
      .padding({
        top: this.resolveTopPadding(),
        bottom: this.resolveBottomPadding()
      })
      .backgroundColor(this.surfaceColor)
      .constraintSize({
        minHeight: this.fillHeight ? '100%' : undefined
      });

      if (this.resolveTopPadding() > 0) {
        Column() {}
          .width('100%')
          .height(this.resolveTopPadding())
          .backgroundColor(this.surfaceColor)
          .expandSafeArea([SafeAreaType.KEYBOARD])
          .zIndex(1);
      }
    }
    .width('100%')
    .constraintSize({
      minHeight: this.fillHeight ? '100%' : undefined
    });
  }
}
