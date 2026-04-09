import { AppState, useAppState } from '../../../app/AppStates';
import { InteractableCard } from '../../../components/card/InteractableCard';

/**
 * 待办卡片骨架。
 * TODO: 后续补充勾选、右滑开启专注、左滑删除等交互。
 */
@ComponentV2
export struct TodoCard {
  @Local private app: AppState = useAppState();
  @Param title: string = 'TodoCard';
  @Param subtitle: string = 'TODO: 显示待办内容、分类和勾选状态。';
  @Param enableSwipeLeft: boolean = true;
  @Param enableSwipeRight: boolean = false;
  @Event onSwipeLeft: () => void = () => {};
  @Event onSwipeRight: () => void = () => {};
  @Event onCardTap: () => void = () => {};

  build() {
    InteractableCard({
      leftHint: '左滑: 删除',
      rightHint: '右滑: 启动专注',
      enableSwipeLeft: this.enableSwipeLeft,
      enableSwipeRight: this.enableSwipeRight,
      onSwipeLeft: () => {
        this.onSwipeLeft();
      },
      onSwipeRight: () => {
        this.onSwipeRight();
      },
      onCardTap: () => {
        this.onCardTap();
      }
    }) {
      Column({ space: 8 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textSecondary);
      }
      .alignItems(HorizontalAlign.Start);
    }
  }
}
