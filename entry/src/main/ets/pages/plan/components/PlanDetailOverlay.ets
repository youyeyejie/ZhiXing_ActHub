import { AppState, useAppState } from '../../../app/AppStates';
import { Plan } from '../../../core/models/Plan';
import { PlanPageState, usePlanPageState } from '../PlanPageState';
import { PlanPickerStyle } from './PlanPickerStyle';

/**
 * 日程详情编辑全屏遮罩层。
 * 支持自动保存与删除撤销联动。
 */
@ComponentV2
export struct PlanDetailOverlay {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();

  @Local private loadedPlanId: string = '';
  @Local private titleDraft: string = '';
  @Local private locationDraft: string = '';
  @Local private descriptionDraft: string = '';
  @Local private isCourseDraft: number = 0;
  @Local private startDateDraft: Date = new Date();
  @Local private startTimeDraft: Date = new Date();
  @Local private endDateDraft: Date = new Date();
  @Local private endTimeDraft: Date = new Date();

  private titleSaveTimerId: number = -1;
  private locationSaveTimerId: number = -1;
  private descriptionSaveTimerId: number = -1;

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  private composeDateTime(datePart: Date, timePart: Date): number {
    const date = new Date(datePart.getTime());
    date.setHours(timePart.getHours(), timePart.getMinutes(), 0, 0);
    return date.getTime();
  }

  private createTimePartDate(hour: number, minute: number): Date {
    const date = new Date();
    date.setHours(hour, minute, 0, 0);
    return date;
  }

  private resolveEditingPlan(): Plan | null {
    const planId = this.normalizeId(this.state.editingPlanId);
    if (planId.length === 0) {
      return null;
    }
    const found = this.state.plans.find((item: Plan) => this.normalizeId(item.id) === planId);
    return found ? found : null;
  }

  private clearTitleSaveTimer(): void {
    if (this.titleSaveTimerId >= 0) {
      clearTimeout(this.titleSaveTimerId);
      this.titleSaveTimerId = -1;
    }
  }

  private clearLocationSaveTimer(): void {
    if (this.locationSaveTimerId >= 0) {
      clearTimeout(this.locationSaveTimerId);
      this.locationSaveTimerId = -1;
    }
  }

  private clearDescriptionSaveTimer(): void {
    if (this.descriptionSaveTimerId >= 0) {
      clearTimeout(this.descriptionSaveTimerId);
      this.descriptionSaveTimerId = -1;
    }
  }

  private clearAllTimers(): void {
    this.clearTitleSaveTimer();
    this.clearLocationSaveTimer();
    this.clearDescriptionSaveTimer();
  }

  private loadDraftFromCurrentPlan(): void {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      this.loadedPlanId = '';
      this.titleDraft = '';
      this.locationDraft = '';
      this.descriptionDraft = '';
      this.isCourseDraft = 0;
      return;
    }

    const now = Date.now();
    const startMs = plan.startTime > 0 ? plan.startTime : now;
    const endMs = plan.endTime > plan.startTime ? plan.endTime : (startMs + 60 * 60 * 1000);
    this.loadedPlanId = this.normalizeId(plan.id);
    this.titleDraft = this.normalizeText(plan.content);
    this.locationDraft = this.normalizeText(plan.location);
    this.descriptionDraft = this.normalizeText(plan.description);
    this.isCourseDraft = plan.isCourse === 1 ? 1 : 0;
    this.startDateDraft = new Date(startMs);
    this.startTimeDraft = new Date(startMs);
    this.endDateDraft = new Date(endMs);
    this.endTimeDraft = new Date(endMs);
  }

  private scheduleTitleSave(): void {
    this.clearTitleSaveTimer();
    this.titleSaveTimerId = setTimeout(() => {
      this.persistTitleDraft();
    }, 420);
  }

  private scheduleLocationSave(): void {
    this.clearLocationSaveTimer();
    this.locationSaveTimerId = setTimeout(() => {
      this.persistLocationDraft();
    }, 520);
  }

  private scheduleDescriptionSave(): void {
    this.clearDescriptionSaveTimer();
    this.descriptionSaveTimerId = setTimeout(() => {
      this.persistDescriptionDraft();
    }, 680);
  }

  private persistTitleDraft(): void {
    this.clearTitleSaveTimer();
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    const nextTitle = this.normalizeText(this.titleDraft);
    const currentTitle = this.normalizeText(plan.content);
    if (nextTitle === currentTitle) {
      return;
    }
    this.state.updatePlanContent(this.normalizeId(plan.id), nextTitle);
  }

  private persistLocationDraft(): void {
    this.clearLocationSaveTimer();
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    const nextLocation = this.normalizeText(this.locationDraft);
    const currentLocation = this.normalizeText(plan.location);
    if (nextLocation === currentLocation) {
      return;
    }
    this.state.updatePlanLocation(this.normalizeId(plan.id), nextLocation);
  }

  private persistDescriptionDraft(): void {
    this.clearDescriptionSaveTimer();
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    const nextDescription = this.normalizeText(this.descriptionDraft);
    const currentDescription = this.normalizeText(plan.description);
    if (nextDescription === currentDescription) {
      return;
    }
    this.state.updatePlanDescription(this.normalizeId(plan.id), nextDescription);
  }

  private persistTimeDraftIfValid(): void {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    const startMs = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    const endMs = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    if (endMs <= startMs) {
      return;
    }
    this.state.updatePlanTime(this.normalizeId(plan.id), startMs, endMs);
  }

  private flushDraftSave(): void {
    this.persistTitleDraft();
    this.persistLocationDraft();
    this.persistDescriptionDraft();
    this.persistTimeDraftIfValid();
  }

  private resolveTypeLabel(type: number): string {
    return type === 1 ? '课程' : '日程';
  }

  private resolveTypeRenderToken(type: number): string {
    return `${type}_${this.isCourseDraft}`;
  }

  private switchType(isCourse: number): void {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    const nextType = isCourse === 1 ? 1 : 0;
    if (this.isCourseDraft === nextType) {
      return;
    }
    this.isCourseDraft = nextType;
    this.state.updatePlanType(this.normalizeId(plan.id), nextType);
  }

  private closeOverlay(): void {
    this.flushDraftSave();
    this.state.closePlanDetail();
    this.loadedPlanId = '';
  }

  private deleteCurrentPlan(): void {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    this.flushDraftSave();
    this.state.closePlanDetail();
    this.state.requestDeletePlan(this.normalizeId(plan.id));
    this.loadedPlanId = '';
  }

  @Builder
  private buildTypeChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(12)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildDetailCard() {
    Column({ space: 12 }) {
      Text('详情编辑')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
        .width('100%');

      TextInput({ text: this.titleDraft, placeholder: '标题' })
        .width('100%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.titleDraft = value;
          this.scheduleTitleSave();
        })
        .onBlur(() => {
          this.persistTitleDraft();
        });

      Text('开始时间')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);

      Row({ space: PlanPickerStyle.ROW_SPACE }) {
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: this.startDateDraft
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
            this.startDateDraft = value;
            this.persistTimeDraftIfValid();
          });

        TimePicker({ selected: this.startTimeDraft })
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
            this.startTimeDraft = this.createTimePartDate(value.hour, value.minute);
            this.persistTimeDraftIfValid();
          });
      }
      .width('100%');

      Text('结束时间')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);

      Row({ space: PlanPickerStyle.ROW_SPACE }) {
        DatePicker({
          start: new Date('2000-1-1'),
          end: new Date('2100-12-31'),
          selected: this.endDateDraft
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
            this.endDateDraft = value;
            this.persistTimeDraftIfValid();
          });

        TimePicker({ selected: this.endTimeDraft })
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
            this.endTimeDraft = this.createTimePartDate(value.hour, value.minute);
            this.persistTimeDraftIfValid();
          });
      }
      .width('100%');

      TextInput({ text: this.locationDraft, placeholder: '地点（选填）' })
        .width('100%')
        .height(46)
        .fontSize(14)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 9, bottom: 9 })
        .onChange((value: string) => {
          this.locationDraft = value;
          this.scheduleLocationSave();
        })
        .onBlur(() => {
          this.persistLocationDraft();
        });

      TextArea({ text: this.descriptionDraft, placeholder: '描述（选填）' })
        .width('100%')
        .height(92)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.descriptionDraft = value;
          this.scheduleDescriptionSave();
        })
        .onBlur(() => {
          this.persistDescriptionDraft();
        });

      Row({ space: 10 }) {
        ForEach([0, 1], (type: number) => {
          this.buildTypeChip(this.resolveTypeLabel(type), this.isCourseDraft === type, () => {
            this.switchType(type);
          });
        }, (type: number) => this.resolveTypeRenderToken(type));
      }
      .width('100%');


    }
    .width('100%');
  }

  build() {
    if (this.state.isDetailVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.app.theme.palette.mask)
          .opacity(0.5)
          .onClick(() => {
            this.closeOverlay();
          });

        if (this.resolveEditingPlan() === null) {
          Column({ space: 8 }) {
            Text('未找到日程')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.app.theme.palette.textPrimary);
            Text('该日程可能已被删除。')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }
          .width('82%')
          .padding({ left: 16, right: 16, top: 20, bottom: 20 })
          .borderRadius(18)
          .backgroundColor(this.app.theme.palette.surface);
        } else {
          Column() {
            Scroll() {
              Column() {
                this.buildDetailCard();
              }
              .width('100%');
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off);
          }
          .width('84%')
          .height('74%')
          .padding({ left: 14, right: 14, top: 16, bottom: 14 })
          .borderRadius(18)
          .backgroundColor(this.app.theme.palette.surface)
          .shadow({ radius: 20, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 8 })
          .onClick(() => {
          })
          .onAppear(() => {
            const currentPlan = this.resolveEditingPlan();
            const currentPlanId = currentPlan ? this.normalizeId(currentPlan.id) : '';
            if (this.loadedPlanId !== currentPlanId) {
              this.loadDraftFromCurrentPlan();
            }
          });
        }
      }
      .width('100%')
      .height('100%')
      .focusable(true)
      .onKeyEvent((event: KeyEvent) => {
        if (event.type === KeyType.Down && event.keyCode === 2) {
          this.closeOverlay();
          return true;
        }
        return false;
      });
    }
  }

  aboutToDisappear(): void {
    this.flushDraftSave();
    this.clearAllTimers();
  }
}
