import { AppState, useAppState } from '../../app/AppStates';
import { PageScrollLayout } from './PageScrollLayout';

/**
 * 主标签页统一布局容器。
 * 统一处理整页背景、顶部标题栏和顶部起排的滚动内容。
 */
@ComponentV2
export struct MainTabPageLayout {
  @Local private app: AppState = useAppState();
  @Param title: string = '';
  @Param actionIcon: string = '';
  @Param actionText: string = '';
  @Param actionFillColor: string = '';
  @Event onActionTap: () => void = () => {};
  @BuilderParam content: () => void = this.emptyBuilder;

  @Builder
  private emptyBuilder() {}

  build() {
    Column() {
        Row() {
          Text(this.title)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1);

          if (this.actionIcon.length > 0 || this.actionText.length > 0) {
            Button(this.actionIcon.length > 0 ? this.actionIcon : this.actionText)
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.actionFillColor.length > 0 ? this.actionFillColor : this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(this.onActionTap);
          }
        }
        .padding(20)
        .alignItems(VerticalAlign.Center)
        .expandSafeArea([SafeAreaType.KEYBOARD])
        .backgroundColor(this.app.theme.palette.background)
        .zIndex(1);
      PageScrollLayout() {
        this.content();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
