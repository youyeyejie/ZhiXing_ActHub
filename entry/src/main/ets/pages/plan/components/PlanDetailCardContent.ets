import { PlanEditorContent } from './PlanEditorContent';

/**
 * 日程详情 DetailCard 内容。
 */
@ComponentV2
export struct PlanDetailCardContent {
  build() {
    PlanEditorContent({
      isForCreate: false,
    });
  }
}
