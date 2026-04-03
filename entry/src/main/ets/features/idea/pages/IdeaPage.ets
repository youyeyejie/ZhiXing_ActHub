import { HitokotoCard } from '../components/HitokotoCard';
import { IdeaCard } from '../components/IdeaCard';
import { IdeaEditorSheet } from '../components/IdeaEditorSheet';
import { ActivityHeatmap } from '../components/ActivityHeatmap';

/**
 * 闪记模块主页骨架。
 * TODO: 后续接入搜索遮罩、单列流式列表和详情卡片。
 */
@Component
export struct IdeaPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('闪记')
          .fontSize(28)
          .fontWeight(FontWeight.Bold);
        HitokotoCard();
        IdeaCard();
        ActivityHeatmap();
        IdeaEditorSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
