import { TodoEditorContent } from './TodoEditorContent';

/**
 * 待办详情 DetailCard 内容。
 */
@ComponentV2
export struct TodoDetailCardContent {
  build() {
    TodoEditorContent({
      isForCreate: false,
    });
  }
}
