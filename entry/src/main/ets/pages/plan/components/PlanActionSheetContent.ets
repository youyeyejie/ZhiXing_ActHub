import { PlanEditorContent } from './PlanEditorContent';

/**
 * 日程新建 ActionSheet 内容。
 */
@ComponentV2
export struct PlanActionSheetContent {
  build() {
    PlanEditorContent({
      isForCreate: true,
    });
  }
}
