import { CategoryEditorContent } from './CategoryEditorContent';

/**
 * 分类新建 ActionSheet 内容。
 */
@ComponentV2
export struct CategoryCreateContent {
  build() {
    CategoryEditorContent({
      isForCreate: true,
    });
  }
}