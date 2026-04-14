import { Idea } from "../../../core/models/Idea";
import { AppState, useAppState } from "../../../app/AppStates";
import { InteractableCard } from "../../../components/card/InteractableCard";

/**
 * 闪记卡片组件。
 * 支持显示标题、内容摘要、创建时间，提供左滑删除交互。
 */
@ComponentV2
export struct IdeaCard {
  @Local private app: AppState = useAppState();
  @Param idea: Idea = new Idea();
  @Event onDeleteRequest: (idea: Idea) => void = (_idea: Idea) => {};
  @Event onTap: (idea: Idea) => void = (_idea: Idea) => {};

  /**
   * 格式化时间显示。
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const isYesterday = date.toDateString() === yesterday.toDateString();

    const timeStr = `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;

    if (isToday) {
      return `今天 ${timeStr}`;
    }
    if (isYesterday) {
      return `昨天 ${timeStr}`;
    }
    return `${date.getMonth() + 1}/${date.getDate()} ${timeStr}`;
  }

  build() {
    InteractableCard({
      leftHint: "删除",
      enableSwipeLeft: true,
      enableSwipeRight: false,
      cornerRadius: 20,
      contentPadding: 0,
      outerPaddingVertical: 0,
      shadowRadius: 10,
      shadowOffsetY: 3,
      swipeLeftColor: "#EF4444",
      onSwipeLeft: () => {
        this.onDeleteRequest(this.idea);
      },
      onCardTap: () => {
        this.onTap(this.idea);
      },
    }) {
      Column({ space: 8 }) {
        if (this.idea.title && this.idea.title.length > 0) {
          Text(this.idea.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }

        Text(this.idea.content)
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
          .maxLines(6)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.formatTime(this.idea.timestamp))
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
          .margin({ top: 4 })
      }
      .width("100%")
      .padding(16)
      .borderRadius(20)
      .backgroundColor(this.app.theme.palette.surface)
      .alignItems(HorizontalAlign.Start)
    };
  }
}
