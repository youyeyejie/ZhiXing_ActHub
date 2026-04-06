import { AppState, useAppState } from '../../app/AppStates';
import { CircleButton } from '../buttons/CircleButton';
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
  @Param actionButtonSize: number = 46;
  @Param actionFillColor: string = '';
  @Event onActionTap: () => void = () => {};
  @BuilderParam content: () => void = this.emptyBuilder;

  @Builder
  private emptyBuilder() {}

  build() {
    Column() {
      PageScrollLayout() {
        Row() {
          Text(this.title)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1);

          if (this.actionIcon.length > 0 || this.actionText.length > 0) {
            CircleButton({
              icon: this.actionIcon,
              text: this.actionText,
              buttonSize: this.actionButtonSize,
              fillColor: this.actionFillColor.length > 0 ? this.actionFillColor : this.app.theme.palette.primary,
              onTap: this.onActionTap
            });
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        this.content();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
