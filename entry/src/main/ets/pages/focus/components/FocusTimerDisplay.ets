import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine, FocusState } from '../../../core/services/FocusTimerEngine';

@ComponentV2
export struct FocusTimerDisplay {
  @Local private app: AppState = useAppState();
  
  @Require @Param isEditingTime: boolean;
  @Require @Param customDuration: number;
  
  @Event onToggleEdit: (edit: boolean) => void = () => {};
  @Event onDurationChange: (duration: number) => void = () => {};

  private pickerMin: number = 25;
  private pickerSec: number = 0;

  private minutesRange: string[] = this.generateTimeRange(61);
  private secondsRange: string[] = this.generateTimeRange(60);

  private generateTimeRange(max: number): string[] {
    let result: string[] = [];
    for (let i = 0; i < max; i++) {
      result.push(i.toString().padStart(2, '0'));
    }
    return result;
  }

  private get engine(): FocusTimerEngine {
    return this.app.focusEngine;
  }

  @Monitor("isEditingTime")
  onEditStateChange() {
    if (this.isEditingTime) {
      this.pickerMin = Math.floor(this.customDuration / 60);
      this.pickerSec = this.customDuration % 60;
    } 
  }

  private emitCurrentChange() {
    const total = this.pickerMin * 60 + this.pickerSec;
    this.onDurationChange(total > 0 ? total : 60);
  }

  private formatTime(secs: number): string {
    const m = Math.floor(secs / 60).toString().padStart(2, '0');
    const s = (secs % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  build() {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.Center }) {
        Progress({
          value: this.engine.state === FocusState.IDLE ? 100 : this.engine.getLeftSeconds(),
          total: this.engine.state === FocusState.IDLE ? 100 : (this.engine.totalSeconds > 0 ? this.engine.totalSeconds : 100),
          type: ProgressType.Ring
        })
          .width(238)
          .height(238)
          .color(this.app.theme.palette.primary)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .style({ strokeWidth: 20, enableSmoothEffect: true })

        Stack({ alignContent: Alignment.Center }) {
          if (this.isEditingTime) {
            Row() {
              TextPicker({ range: this.minutesRange, selected: this.pickerMin })
                .onChange((value: string | string[], index: number | number[]) => {
                  this.pickerMin = typeof index === 'number' ? index : index[0];
                  this.emitCurrentChange(); 
                })
                .textStyle({ color: this.app.theme.palette.textSecondary, font: { size: 16 } })
                .selectedTextStyle({ color: this.app.theme.palette.textPrimary, font: { size: 40, weight: FontWeight.Bold } })
                .width(60)
                .canLoop(true)

              Text(':')
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.app.theme.palette.textPrimary)
                .margin({ bottom: 4 })

              TextPicker({ range: this.secondsRange, selected: this.pickerSec })
                .onChange((value: string | string[], index: number | number[]) => {
                  this.pickerSec = typeof index === 'number' ? index : index[0];
                  this.emitCurrentChange(); 
                })
                .textStyle({ color: this.app.theme.palette.textSecondary, font: { size: 16 } })
                .selectedTextStyle({ color: this.app.theme.palette.textPrimary, font: { size: 40, weight: FontWeight.Bold } })
                .width(60)
                .canLoop(true)
            }
            .height(140)
            .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.9, y: 0.9 })).animation({ duration: 250, curve: Curve.EaseInOut }))
            
          } else {
            Column({ space: 4 }) {
              Text(this.engine.state === FocusState.IDLE ? this.formatTime(this.customDuration) : this.engine.getFormattedRemainingTime())
                .fontSize(56)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.app.theme.palette.textPrimary)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  if (this.engine.state === FocusState.IDLE) {
                    this.onToggleEdit(true);
                  }
                })
                
              Text(this.engine.getCurrentStageName())
                .fontSize(15)
                .fontColor(this.app.theme.palette.textSecondary)
                .textAlign(TextAlign.Center)
            }
            .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.9, y: 0.9 })).animation({ duration: 250, curve: Curve.EaseInOut }))
          }
        }
        .width('100%')
        .height('100%')
      }
      .width(238)
      .height(238)
      .onClick(() => {})
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}