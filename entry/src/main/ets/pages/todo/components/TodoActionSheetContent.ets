import { TodoEditorContent } from './TodoEditorContent';

/**
 * 待办新建 ActionSheet 内容。
 */
@ComponentV2
export struct TodoActionSheetContent {
  build() {
    TodoEditorContent({
      hideInnerHeader: true,
    });
  }
}
