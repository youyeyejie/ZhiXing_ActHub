import { AppState, useAppState } from '../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../core/services/FocusTimerEngine';
import { FocusTimerDisplay } from './components/FocusTimerDisplay';
import { FocusTaskSelector } from './components/FocusTaskSelector';
import { FocusControlButtons } from './components/FocusControlButtons';
import { TodoPickerSheet } from './components/TodoPickerSheet';
import { TimeSelectionSheet } from './components/TimeSelectionSheet';
import promptAction from '@ohos.promptAction';

/**
 * 组件功能简介：
 * - 专注主页面，作为专注模块的核心容器，整合任务选择、倒计时显示、高级时间设置与专注状态控制功能。
 *
 * 可传入项：
 * - @Param onRequestDismiss: () => void (请求关闭/下拉收起当前专注页面的回调函数)
 *
 * 返回行为：
 * - 渲染全屏的专注沉浸界面，自上而下包含：顶部导航栏（退出与设置按钮）、任务选择器、中心倒计时展示区、控制按钮组以及底部励志标语。
 *
 * 副作用：
 * - 管理 customDuration（工作时长）和 customRestDuration（休息时长）的本地状态，并向下级组件分发传递。
 * - 交互时会通过 `app.nav` 挂载并唤起 `TodoPickerSheet` (待办选择弹层) 和 `TimeSelectionSheet` (高级时间设置弹层)。
 * - 拦截全屏背景的点击事件，用于快捷退出中心时间滚轮的编辑状态。
 * - 在引擎非空闲状态（计时中）点击设置按钮时，会拦截操作并调用系统 `promptAction.showToast` 弹出警告提示。
 */
 
@ComponentV2
export struct FocusPage {
  @Local private app: AppState = useAppState();
  @Param onRequestDismiss: () => void = () => {};
  
  @Local private customDuration: number = 25 * 60; 
  @Local private customRestDuration: number = 5 * 60; 
  @Local private isEditingTime: boolean = false;
  
  private openTodoPicker(): void {
    this.app.nav.openActionSheet(() => { this.buildTodoPickerContent() });
  }

  @Builder
  private buildTodoPickerContent() {
    TodoPickerSheet();
  }

  @Builder
  private buildTimeSheetContent() { 
    TimeSelectionSheet({
      initialWorkDuration: this.customDuration,
      onSave: (workDuration: number, restDuration: number) => {
        this.customDuration = workDuration;
        this.customRestDuration = restDuration; 
      },
      onSheetClose: () => {
        this.isEditingTime = false; 
      }
    });
  }

  build() {
    Stack() {
      Column() {
        Row() {
          // 左侧：下拉退出按钮
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(24)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
              .fontColor([this.app.theme.palette.textPrimary])
            }
            .type(ButtonType.Circle)
            .width(40)
            .height(40)
            .backgroundColor(this.app.theme.palette.surface)
            .onClick(() => {
              this.onRequestDismiss();
            })
            .margin({ left: 16, top: 16 })

          Blank() 

          // 右侧：快捷编辑按钮
          Button() {
            SymbolGlyph($r('sys.symbol.square_and_pencil')) 
              .fontSize(22)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
              .fontColor([this.app.theme.palette.textPrimary])
            }
            .type(ButtonType.Circle)
            .width(40)
            .height(40)
            .backgroundColor(this.app.theme.palette.surface)
            .onClick(() => {
              // 判断当前是否处于空闲状态
              if (this.app.focusEngine.state === FocusState.IDLE) {
                this.app.nav.openActionSheet(() => { this.buildTimeSheetContent() }); 
              } else {
                // 非空闲状态，弹出提示
                try {
                  promptAction.showToast({ message: "计时中无法修改时间设置哦", duration: 1500 });
                } catch (e) {}
              }
            })
            .margin({ right: 16, top: 16 }) // 与左边保持对称
        }
        .width('100%')

        Column({ space: 0 }) {
          FocusTaskSelector({ 
            onOpenPicker: () => {
              this.openTodoPicker();
            }
          })
            .height(44)
            .margin({ top: 5 })

          FocusTimerDisplay({
            isEditingTime: this.isEditingTime,
            customDuration: this.customDuration,
            onToggleEdit: (edit: boolean) => {
              this.isEditingTime = edit;
            },
            onDurationChange: (duration: number) => {
              this.customDuration = duration;
            }
          })
            .margin({ top: 36 }) 
          
          FocusControlButtons({ 
            customDuration: this.customDuration,
            customRestDuration: this.customRestDuration,
            goBackIndex: () => {
              if (this.isEditingTime) {
                this.isEditingTime = false;
              }
            }
          })
            .margin({ top: 20 })

          Text('"保持专注，心无旁骛"')
            .fontSize(18)
            .fontColor(this.app.theme.palette.textTertiary)
            .textAlign(TextAlign.Center)
            .margin({ top: 60 })
        }
        .width('100%')
        .layoutWeight(1) 
        .justifyContent(FlexAlign.Center) 
        .alignItems(HorizontalAlign.Center) 
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background)
      .padding({ top: 30 })
      .onClick(() => {
        if (this.isEditingTime) {
          this.isEditingTime = false;
        }
      })
    }
    .width('100%')
    .height('100%');
  }
}