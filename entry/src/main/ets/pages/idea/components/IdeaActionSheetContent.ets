import { IdeaEditorContent } from "./IdeaEditorContent";

/**
 * 闪记新建 ActionSheet 内容。
 */
@ComponentV2
export struct IdeaActionSheetContent {
  build() {
    IdeaEditorContent({
      isForCreate: true,
    });
  }
}
