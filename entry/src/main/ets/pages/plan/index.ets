import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口、浮动新建按钮和详情弹层。
 */
@ComponentV2
export struct PlanPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('日程')
          .fontSize(28)
          .fontWeight(FontWeight.Bold);
        WeekCalendar();
        TimelineView();
        PlanCard();
        PlanEditorSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
