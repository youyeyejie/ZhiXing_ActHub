import { IdeaEditorContent } from "./IdeaEditorContent";

/**
 * 闪记详情 DetailCard 内容。
 */
@ComponentV2
export struct IdeaDetailCardContent {
  build() {
    IdeaEditorContent({
      hideInnerHeader: true,
    });
  }
}
