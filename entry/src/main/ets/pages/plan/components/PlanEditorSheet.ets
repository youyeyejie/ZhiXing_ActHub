import { AppState, useAppState } from '../../../app/AppStates';
import { ActionSheet, ActionSheetController } from '../../../components/card/ActionSheet';
import { PlanPageState, usePlanPageState } from '../PlanPageState';
import { PlanPickerStyle } from './PlanPickerStyle';
import promptAction from '@ohos.promptAction';

/**
 * 日程新建半屏页。
 * 使用 ActionSheet 承载字段编辑，时间为必填项。
 */
@ComponentV2
export struct PlanEditorSheet {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  private sheetController: ActionSheetController = new ActionSheetController();

  @Local private draftTitle: string = '';
  @Local private draftLocation: string = '';
  @Local private draftDescription: string = '';
  @Local private draftIsCourse: number = 0;
  @Local private draftStartDate: Date = new Date();
  @Local private draftStartTime: Date = new Date();
  @Local private draftEndDate: Date = new Date();
  @Local private draftEndTime: Date = new Date();

  aboutToAppear(): void {
    this.prepareDraftForCreate();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private buildDateWithTime(dayMs: number, hour: number, minute: number): Date {
    const date = new Date(dayMs);
    date.setHours(hour, minute, 0, 0);
    return date;
  }

  private buildTimePartDate(hour: number, minute: number): Date {
    const date = new Date();
    date.setHours(hour, minute, 0, 0);
    return date;
  }

  private composeDateTime(datePart: Date, timePart: Date): number {
    const date = new Date(datePart.getTime());
    date.setHours(timePart.getHours(), timePart.getMinutes(), 0, 0);
    return date.getTime();
  }

  private async prepareDraftForCreate(): Promise<void> {
    await this.state.refreshAll();
    if (this.state.creatingPlanId.length === 0) {
      this.state.openCreatePlan();
    }
    const selectedDayStart = new Date(this.state.selectedDate);
    selectedDayStart.setHours(0, 0, 0, 0);
    const dayMs = selectedDayStart.getTime();

    this.draftTitle = '';
    this.draftLocation = '';
    this.draftDescription = '';
    this.draftIsCourse = 0;
    this.draftStartDate = new Date(dayMs);
    this.draftEndDate = new Date(dayMs);
    this.draftStartTime = this.buildDateWithTime(dayMs, 9, 0);
    this.draftEndTime = this.buildDateWithTime(dayMs, 10, 0);
  }

  private ensureValidDraftTimeRange(): void {
    const start = this.composeDateTime(this.draftStartDate, this.draftStartTime);
    const end = this.composeDateTime(this.draftEndDate, this.draftEndTime);
    if (end > start) {
      return;
    }
    const fallbackEnd = new Date(start + 60 * 60 * 1000);
    this.draftEndDate = fallbackEnd;
    this.draftEndTime = fallbackEnd;
  }

  private async submit(): Promise<void> {
    const title = `${this.draftTitle}`.trim();
    const startTime = this.composeDateTime(this.draftStartDate, this.draftStartTime);
    const endTime = this.composeDateTime(this.draftEndDate, this.draftEndTime);
    if (title.length === 0) {
      this.safeToast('请填写日程标题');
      return;
    }
    if (endTime <= startTime) {
      this.safeToast('结束时间必须晚于开始时间');
      return;
    }

    const ok = await this.state.createPlan(
      title,
      startTime,
      endTime,
      this.draftLocation,
      this.draftIsCourse,
      this.draftDescription
    );
    if (!ok) {
      this.safeToast('创建失败：请检查必填项');
      return;
    }
    this.close();
    this.safeToast('日程已添加');
  }

  private close(): void {
    this.state.closePlanEditor();
    this.draftTitle = '';
    this.draftLocation = '';
    this.draftDescription = '';
  }

  private resolveTypeLabel(type: number): string {
    return type === 1 ? '课程' : '日程';
  }

  private resolveTypeRenderToken(type: number): string {
    return `${type}_${this.draftIsCourse}`;
  }

  @Builder
  private buildTypeChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(30)
      .fontSize(12)
      .backgroundColor(selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildContent() {
    Column({ space: 12 }) {
      Row() {
        Text('新建日程')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        Button('保存')
          .type(ButtonType.Capsule)
          .height(40)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .onClick(async () => {
            await this.submit();
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      TextInput({ text: this.draftTitle, placeholder: '日程标题（必填）' })
        .fontSize(14)
        .width('100%')
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftTitle = value;
        });

      Text('开始时间（必填）')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Row({ space: PlanPickerStyle.ROW_SPACE }) {
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: this.draftStartDate
        })
          .lunar(false)
          .layoutWeight(1)
          .height(PlanPickerStyle.PANEL_HEIGHT)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .disappearTextStyle({
            color: this.app.theme.palette.textTertiary,
            font: { size: PlanPickerStyle.DISAPPEAR_FONT_SIZE, weight: FontWeight.Regular }
          })
          .textStyle({
            color: this.app.theme.palette.textSecondary,
            font: { size: PlanPickerStyle.TEXT_FONT_SIZE, weight: FontWeight.Regular }
          })
          .selectedTextStyle({
            color: this.app.theme.palette.primary,
            font: { size: PlanPickerStyle.SELECTED_FONT_SIZE, weight: FontWeight.Medium }
          })
          .onDateChange((value: Date) => {
            this.draftStartDate = value;
            this.ensureValidDraftTimeRange();
          });

        TimePicker({ selected: this.draftStartTime })
          .useMilitaryTime(true)
          .layoutWeight(1)
          .height(PlanPickerStyle.PANEL_HEIGHT)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .disappearTextStyle({
            color: this.app.theme.palette.textTertiary,
            font: { size: PlanPickerStyle.DISAPPEAR_FONT_SIZE, weight: FontWeight.Regular }
          })
          .textStyle({
            color: this.app.theme.palette.textSecondary,
            font: { size: PlanPickerStyle.TEXT_FONT_SIZE, weight: FontWeight.Regular }
          })
          .selectedTextStyle({
            color: this.app.theme.palette.primary,
            font: { size: PlanPickerStyle.SELECTED_FONT_SIZE, weight: FontWeight.Medium }
          })
          .onChange((value) => {
            this.draftStartTime = this.buildTimePartDate(value.hour, value.minute);
            this.ensureValidDraftTimeRange();
          });
      }
      .width('100%');

      Text('结束时间（必填）')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Row({ space: PlanPickerStyle.ROW_SPACE }) {
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: this.draftEndDate
        })
          .lunar(false)
          .layoutWeight(1)
          .height(PlanPickerStyle.PANEL_HEIGHT)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .disappearTextStyle({
            color: this.app.theme.palette.textTertiary,
            font: { size: PlanPickerStyle.DISAPPEAR_FONT_SIZE, weight: FontWeight.Regular }
          })
          .textStyle({
            color: this.app.theme.palette.textSecondary,
            font: { size: PlanPickerStyle.TEXT_FONT_SIZE, weight: FontWeight.Regular }
          })
          .selectedTextStyle({
            color: this.app.theme.palette.primary,
            font: { size: PlanPickerStyle.SELECTED_FONT_SIZE, weight: FontWeight.Medium }
          })
          .onDateChange((value: Date) => {
            this.draftEndDate = value;
            this.ensureValidDraftTimeRange();
          });

        TimePicker({ selected: this.draftEndTime })
          .useMilitaryTime(true)
          .layoutWeight(1)
          .height(PlanPickerStyle.PANEL_HEIGHT)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .disappearTextStyle({
            color: this.app.theme.palette.textTertiary,
            font: { size: PlanPickerStyle.DISAPPEAR_FONT_SIZE, weight: FontWeight.Regular }
          })
          .textStyle({
            color: this.app.theme.palette.textSecondary,
            font: { size: PlanPickerStyle.TEXT_FONT_SIZE, weight: FontWeight.Regular }
          })
          .selectedTextStyle({
            color: this.app.theme.palette.primary,
            font: { size: PlanPickerStyle.SELECTED_FONT_SIZE, weight: FontWeight.Medium }
          })
          .onChange((value) => {
            this.draftEndTime = this.buildTimePartDate(value.hour, value.minute);
            this.ensureValidDraftTimeRange();
          });
      }
      .width('100%');

      TextInput({ text: this.draftLocation, placeholder: '地点（选填）' })
        .fontSize(14)
        .width('100%')
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftLocation = value;
        });
      

      TextArea({ text: this.draftDescription, placeholder: '备注描述（选填）' })
        .fontSize(14)
        .width('100%')
        .height(92)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftDescription = value;
        });

      Row({ space: 10 }) {
        ForEach([0, 1], (type: number) => {
          this.buildTypeChip(this.resolveTypeLabel(type), this.draftIsCourse === type, () => {
            this.draftIsCourse = type;
          });
        }, (type: number) => this.resolveTypeRenderToken(type));
      }
      .width('100%');
    }
    .width('100%');
  }

  build() {
    Column() {
      if (this.state.isEditorVisible) {
        ActionSheet({
          isVisible: true,
          panelHeight: '76%',
          controller: this.sheetController,
          onDismiss: () => {
            this.close();
          }
        }) {
          this.buildContent();
        }
      }
    }
    .width('100%')
    .height('100%');
  }
}
