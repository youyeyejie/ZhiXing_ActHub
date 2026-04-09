import { AppState, useAppState } from '../../../app/AppStates';
import { InteractableCard } from '../../../components/card/InteractableCard';

/**
 * 组件功能简介：
 * - 待办列表项组件，封装卡片展示与手势事件透传。
 * - TODO: 尚未接入完成态勾选与专注联动。
 *
 * 可传入项：
 * - @Param title/subtitle: 卡片主副文本。
 * - @Param enableSwipeLeft/enableSwipeRight: 控制左右滑手势开关。
 * - @Event onSwipeLeft/onSwipeRight: 左右滑动作回调。
 * - @Event onCardTap: 点击卡片回调。
 *
 * 返回行为：
 * - 返回一个 `InteractableCard` 包裹的待办内容区。
 *
 * 副作用：
 * - 手势与点击会触发外部事件回调。
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

  /**
   * 渲染待办卡片，并把手势事件透传给页面层。
   */
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
