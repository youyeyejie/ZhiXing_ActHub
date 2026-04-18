import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 安全区内边距容器，统一处理顶部/底部安全区与额外偏移。
 *
 * 可传入项：
 * - @Param includeTop/includeBottom: 是否自动包含顶部/底部安全区。
 * - @Param extraTop/extraBottom: 额外补偿内边距。
 * - @Param fillHeight: 是否填满可用高度。
 * - @Param surfaceColor: 容器背景色。
 * - @BuilderParam content: 容器主体内容。
 *
 * 返回行为：
 * - 返回应用安全区内边距后的内容容器。
 *
 * 副作用：
 * - 无业务副作用。
 */
@ComponentV2
export struct SafeAreaInsetLayout {
  @Local private app: AppState = useAppState();
  @Param includeTop: boolean = false;
  @Param includeBottom: boolean = false;
  @Param extraTop: number = 0;
  @Param extraBottom: number = 0;
  @Param fillHeight: boolean = true;
  @Param surfaceColor: ResourceColor = this.app.theme.palette.transparent;
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
