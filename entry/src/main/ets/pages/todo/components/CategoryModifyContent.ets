import { CategoryEditorContent } from './CategoryEditorContent';

/**
 * 分类修改 ActionSheet 内容。
 */
@ComponentV2
export struct CategoryModifyContent {
  build() {
    CategoryEditorContent({
      isForCreate: false,
    });
  }
}