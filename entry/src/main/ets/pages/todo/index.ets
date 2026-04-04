import { CategoryFilter } from './components/CategoryFilter';
import { TodoCard } from './components/TodoCard';
import { TodoEditorSheet } from './components/TodoEditorSheet';
import { CircleButton } from '../../components/buttons/CircleButton';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { AppState, useAppState  } from '../../app/AppStates';

/**
 * 待办模块主页骨架。
 * TODO: 后续接入搜索、分类管理和待办详情弹层。
 */
@ComponentV2
export struct TodoPage {
  @Local private app: AppState = useAppState();
  @Local private topInset: number = SafeAreaUtils.getSearchTopInset();

  private searchDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildSearchDialog,
    customStyle: true,
    autoCancel: false,
    alignment: DialogAlignment.Top
  });

  aboutToAppear(): void {
    this.topInset = SafeAreaUtils.getSearchTopInset();
  }

  @Builder
  private buildSearchDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.app.theme.palette.background);

      SearchOverlay({
        title: '待办搜索',
        placeholder: '搜索待办内容/分类',
        scope: SearchScope.Todo,
        topInset: this.topInset,
        onDismiss: () => {
          this.searchDialogController.close();
        }
      });
    }
    .width('100%')
    .height('100%');
  }

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
              this.app.nav.openTodoSearch();
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
