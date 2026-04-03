import { CategoryFilter } from '../components/CategoryFilter';
import { TodoCard } from '../components/TodoCard';
import { TodoEditorSheet } from '../components/TodoEditorSheet';

/**
 * 待办模块主页骨架。
 * TODO: 后续接入搜索、分类管理和待办详情弹层。
 */
@Component
export struct TodoPage {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('待办')
          .fontSize(28)
          .fontWeight(FontWeight.Bold);
        CategoryFilter();
        TodoCard();
        TodoEditorSheet();
      }
      .alignItems(HorizontalAlign.Start)
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA');
  }
}
