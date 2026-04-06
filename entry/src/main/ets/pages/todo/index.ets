import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { TodoEditorSheet } from './components/TodoEditorSheet';
import { CircleButton } from '../../components/buttons/CircleButton';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState  } from '../../app/AppStates';

/**
 * 待办模块主页骨架。
 * TODO: 后续接入搜索、分类管理和待办详情弹层。
 */
@ComponentV2
export struct TodoPage {
  @Local private app: AppState = useAppState();

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Text('待办')
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
              this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索待办'));
            }
          });
        }
        .width('100%');
        CategoryFilter();
        TodoCard();
        TodoEditorSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
