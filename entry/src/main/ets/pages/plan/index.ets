import { WeekCalendar } from './components/WeekCalendar';
import { TimelineView } from './components/TimelineView';
import { PlanCard } from './components/PlanCard';
import { PlanEditorSheet } from './components/PlanEditorSheet';
import { CircleButton } from '../../components/buttons/CircleButton';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';

/**
 * 日程模块主页骨架。
 * TODO: 后续接入搜索入口、浮动新建按钮和详情弹层。
 */
@ComponentV2
export struct PlanPage {
  @Local private app: AppState = useAppState();

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Text('日程')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1);

          CircleButton({
            icon: '?',
            text: '搜索',
            buttonSize: 46,
            fillColor: this.app.theme.palette.primary,
            onTap: () => {
              this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('plan', '搜索日程'));
            }
          });
        }
        .width('100%');
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
    .backgroundColor(this.app.theme.palette.background);
  }
}
