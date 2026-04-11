import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine } from '../../../core/services/FocusTimerEngine';

/**
 * 专注任务选择器组件。
 * 显示当前任务或提供选择任务的入口。
 * todo：打开任务选择器
 */

@ComponentV2
export struct FocusTaskSelector {
  @Local private app: AppState = useAppState();
  @Require @Param engine: FocusTimerEngine;

  build() {
    Column({ space: 8 }) {
      if (this.engine.hasTodo()) {
        // 有关联待办时显示
        Text(`当前任务: TODO_ID_${this.engine.todoId.substring(0, 8)}`)
          .fontSize(16)
          .fontColor(this.app.theme.palette.textPrimary)
          .textAlign(TextAlign.Center)
      } else {
        // 无关联待办时显示提示（可点击选择）
        Row({ space: 8 }) {
          Text(){
            SymbolSpan($r('sys.symbol.bookmark'))
            .fontWeight(FontWeight.Normal)
            .fontSize(14)
            .fontColor([this.app.theme.palette.textSecondary])
          }
          Text('选择专注任务')
            .fontSize(16)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('70%') // 缩小一些（80% -> 70%）
    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
    .backgroundColor(this.app.theme.palette.surface) // 使用surface背景色
    .borderRadius(10)
    .border({ width: 1, color: this.app.theme.palette.border }) // 细边框
    .onClick(() => {
      // 点击任务区域打开待办选择器
      console.log('打开待办选择器');
      // TODO: 打开 TodoPickerSheet
    })
  }
}
