import { AppState, useAppState } from '../../../app/AppStates';
import { Plan } from '../../../core/models/Plan';
import { PlanPageState, usePlanPageState } from '../PlanPageState';
import { PlanPickerStyle } from './PlanPickerStyle';

/**
 * 日程编辑器内容。
 * hideInnerHeader=true 用于新建 ActionSheet，false 用于详情 DetailCard。
 */
@ComponentV2
export struct PlanEditorContent {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  @Param hideInnerHeader: boolean = false;

  @Local private saving: boolean = false;
  @Local private saveEnabled: boolean = false;

  @Local private loadedPlanId: number = 0;
  @Local private titleDraft: string = '';
  @Local private initialTitle: string = '';
  @Local private locationDraft: string = '';
  @Local private initialLocation: string = '';
  @Local private descriptionDraft: string = '';
  @Local private initialDescription: string = '';
  @Local private isCourseDraft: number = 0;
  @Local private initialIsCourse: number = 0;
  @Local private startDateDraft: Date = new Date();
  @Local private startTimeDraft: Date = new Date();
  @Local private initialStartMs: number = 0;
  @Local private endDateDraft: Date = new Date();
  @Local private endTimeDraft: Date = new Date();
  @Local private initialEndMs: number = 0;

  aboutToAppear(): void {
    if (this.hideInnerHeader) {
      this.prepareDraftForCreate();
      return;
    }
    this.loadDraftFromCurrentPlan();
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
  }

  private buildDateWithTime(dayMs: number, hour: number, minute: number): Date {
    const date = new Date(dayMs);
    date.setHours(hour, minute, 0, 0);
    return date;
  }

  private composeDateTime(datePart: Date, timePart: Date): number {
    const date = new Date(datePart.getTime());
    date.setHours(timePart.getHours(), timePart.getMinutes(), 0, 0);
    return date.getTime();
  }

  private formatTwoDigits(value: number): string {
    return `${value}`.padStart(2, '0');
  }

  private formatDateTimeLabel(datePart: Date, timePart: Date): string {
    const dateTime = new Date(this.composeDateTime(datePart, timePart));
    const year = `${dateTime.getFullYear()}`;
    const month = this.formatTwoDigits(dateTime.getMonth() + 1);
    const day = this.formatTwoDigits(dateTime.getDate());
    const hour = this.formatTwoDigits(dateTime.getHours());
    const minute = this.formatTwoDigits(dateTime.getMinutes());
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }

  private openDateTimeDialog(selected: Date, onAccept: (value: Date) => void): void {
    try {
      this.getUIContext().showDatePickerDialog({
        start: new Date(PlanPickerStyle.DATE_RANGE_START),
        end: new Date(PlanPickerStyle.DATE_RANGE_END),
        selected,
        showTime: true,
        useMilitaryTime: true,
        dateTimeOptions: { hour: '2-digit', minute: '2-digit' },
        disappearTextStyle: {
          color: this.app.theme.palette.textTertiary,
          font: { size: PlanPickerStyle.DISAPPEAR_FONT_SIZE, weight: FontWeight.Regular }
        },
        textStyle: {
          color: this.app.theme.palette.textSecondary,
          font: { size: PlanPickerStyle.TEXT_FONT_SIZE, weight: FontWeight.Regular }
        },
        selectedTextStyle: {
          color: this.app.theme.palette.primary,
          font: { size: PlanPickerStyle.SELECTED_FONT_SIZE, weight: FontWeight.Medium }
        },
        onDateAccept: (value: Date) => {
          onAccept(value);
        }
      });
    } catch (_error) {}
  }

  private openStartDateTimeDialog(): void {
    const selected = new Date(this.composeDateTime(this.startDateDraft, this.startTimeDraft));
    this.openDateTimeDialog(selected, (value: Date) => {
      const accepted = new Date(value.getTime());
      this.startDateDraft = accepted;
      this.startTimeDraft = accepted;
      this.ensureValidDraftTimeRange();
      this.recalculateSaveEnabled();
    });
  }

  private openEndDateTimeDialog(): void {
    const selected = new Date(this.composeDateTime(this.endDateDraft, this.endTimeDraft));
    this.openDateTimeDialog(selected, (value: Date) => {
      const accepted = new Date(value.getTime());
      this.endDateDraft = accepted;
      this.endTimeDraft = accepted;
      this.ensureValidDraftTimeRange();
      this.recalculateSaveEnabled();
    });
  }

  private ensureValidDraftTimeRange(): void {
    const start = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    const end = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    if (end > start) {
      return;
    }
    const fallbackEnd = new Date(start + 60 * 60 * 1000);
    this.endDateDraft = fallbackEnd;
    this.endTimeDraft = fallbackEnd;
  }

  private resolveEditingPlan(): Plan | null {
    const planId = this.normalizeId(this.state.editingPlanId);
    if (planId <= 0) {
      return null;
    }
    const found = this.state.plans.find((item: Plan) => this.normalizeId(item.id) === planId);
    return found ? found : null;
  }

  private async prepareDraftForCreate(): Promise<void> {
    await this.state.refreshAll();
    const selectedDayStart = new Date(this.state.selectedDate);
    selectedDayStart.setHours(0, 0, 0, 0);
    const dayMs = selectedDayStart.getTime();

    this.loadedPlanId = 0;
    this.titleDraft = '';
    this.initialTitle = '';
    this.locationDraft = '';
    this.initialLocation = '';
    this.descriptionDraft = '';
    this.initialDescription = '';
    this.isCourseDraft = 0;
    this.initialIsCourse = 0;
    this.startDateDraft = new Date(dayMs);
    this.startTimeDraft = this.buildDateWithTime(dayMs, 9, 0);
    this.endDateDraft = new Date(dayMs);
    this.endTimeDraft = this.buildDateWithTime(dayMs, 10, 0);
    this.initialStartMs = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    this.initialEndMs = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    this.recalculateSaveEnabled();
  }

  private loadDraftFromCurrentPlan(): void {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      this.loadedPlanId = 0;
      this.titleDraft = '';
      this.initialTitle = '';
      this.locationDraft = '';
      this.initialLocation = '';
      this.descriptionDraft = '';
      this.initialDescription = '';
      this.isCourseDraft = 0;
      this.initialIsCourse = 0;
      this.initialStartMs = 0;
      this.initialEndMs = 0;
      this.recalculateSaveEnabled();
      return;
    }

    const now = Date.now();
    const startMs = plan.startTime > 0 ? plan.startTime : now;
    const endMs = plan.endTime > plan.startTime ? plan.endTime : (startMs + 60 * 60 * 1000);
    this.loadedPlanId = this.normalizeId(plan.id);
    this.titleDraft = this.normalizeText(plan.content);
    this.initialTitle = this.titleDraft;
    this.locationDraft = this.normalizeText(plan.location);
    this.initialLocation = this.locationDraft;
    this.descriptionDraft = this.normalizeText(plan.description);
    this.initialDescription = this.descriptionDraft;
    this.isCourseDraft = plan.isCourse === 1 ? 1 : 0;
    this.initialIsCourse = this.isCourseDraft;
    this.startDateDraft = new Date(startMs);
    this.startTimeDraft = new Date(startMs);
    this.initialStartMs = startMs;
    this.endDateDraft = new Date(endMs);
    this.endTimeDraft = new Date(endMs);
    this.initialEndMs = endMs;
    this.recalculateSaveEnabled();
  }

  private hasDraftChanges(): boolean {
    const startMs = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    const endMs = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    return this.normalizeText(this.titleDraft) !== this.initialTitle
      || this.normalizeText(this.locationDraft) !== this.initialLocation
      || this.normalizeText(this.descriptionDraft) !== this.initialDescription
      || this.isCourseDraft !== this.initialIsCourse
      || startMs !== this.initialStartMs
      || endMs !== this.initialEndMs;
  }

  private computeCanSave(): boolean {
    if (this.saving) {
      return false;
    }
    if (this.normalizeText(this.titleDraft).length === 0) {
      return false;
    }
    const startMs = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    const endMs = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    if (endMs <= startMs) {
      return false;
    }
    if (this.hideInnerHeader) {
      return true;
    }
    return this.resolveEditingPlan() !== null;
  }

  private recalculateSaveEnabled(): void {
    this.saveEnabled = this.computeCanSave();
  }

  private async submit(): Promise<void> {
    if (!this.computeCanSave()) {
      this.recalculateSaveEnabled();
      return;
    }
    if (this.hideInnerHeader) {
      await this.submitCreate();
      return;
    }
    await this.submitEdit();
  }

  private async submitCreate(): Promise<void> {
    this.saving = true;
    this.recalculateSaveEnabled();
    const title = this.normalizeText(this.titleDraft);
    const startTime = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    const endTime = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    try {
      const ok = await this.state.createPlan(
        title,
        startTime,
        endTime,
        this.locationDraft,
        this.isCourseDraft,
        this.descriptionDraft,
      );
      if (ok) {
        this.state.closePlanEditor();
        this.app.nav.back(false);
      }
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private async submitEdit(): Promise<void> {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    if (!this.hasDraftChanges()) {
      this.app.nav.back(false);
      return;
    }
    const planId = this.normalizeId(plan.id);
    if (planId <= 0) {
      return;
    }
    const startMs = this.composeDateTime(this.startDateDraft, this.startTimeDraft);
    const endMs = this.composeDateTime(this.endDateDraft, this.endTimeDraft);
    if (endMs <= startMs) {
      return;
    }

    this.saving = true;
    this.recalculateSaveEnabled();
    try {
      await this.state.updatePlanContent(planId, this.normalizeText(this.titleDraft));
      await this.state.updatePlanTime(planId, startMs, endMs);
      await this.state.updatePlanLocation(planId, this.normalizeText(this.locationDraft));
      await this.state.updatePlanDescription(planId, this.normalizeText(this.descriptionDraft));
      await this.state.updatePlanType(planId, this.isCourseDraft);

      this.initialTitle = this.normalizeText(this.titleDraft);
      this.initialLocation = this.normalizeText(this.locationDraft);
      this.initialDescription = this.normalizeText(this.descriptionDraft);
      this.initialIsCourse = this.isCourseDraft;
      this.initialStartMs = startMs;
      this.initialEndMs = endMs;
      this.app.nav.back(false);
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private resolveTypeLabel(type: number): string {
    return type === 1 ? '课程' : '日程';
  }

  private resolveTypeRenderToken(type: number): string {
    return `${type}_${this.isCourseDraft}`;
  }

  private switchType(isCourse: number): void {
    const nextType = isCourse === 1 ? 1 : 0;
    if (this.isCourseDraft === nextType) {
      return;
    }
    this.isCourseDraft = nextType;
    this.recalculateSaveEnabled();
  }

  private canDelete(): boolean {
    if (this.hideInnerHeader || this.saving) {
      return false;
    }
    return this.resolveEditingPlan() !== null;
  }

  private deleteCurrentPlan(): void {
    const plan = this.resolveEditingPlan();
    if (plan === null) {
      return;
    }
    this.state.closePlanDetail();
    this.state.requestDeletePlan(this.normalizeId(plan.id));
    this.loadedPlanId = 0;
    this.app.nav.back(false);
  }

  @Builder
  private buildSaveButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.save'))
        .fontSize(18)
        .fontColor([this.app.theme.palette.surface]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.primary)
      .enabled(this.saveEnabled)
      .onClick(() => {
        this.submit();
      });
  }

  @Builder
  private buildDeleteButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(18)
        .fontColor([this.app.theme.palette.danger]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.surface)
      .enabled(this.canDelete())
      .onClick(() => {
        this.deleteCurrentPlan();
      });
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
  private buildContent() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Text(this.hideInnerHeader ? '新建日程' : '编辑日程')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        this.buildSaveButton();
        if (!this.hideInnerHeader) {
          this.buildDeleteButton();
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      TextInput({ text: this.titleDraft, placeholder: this.hideInnerHeader ? '日程标题（必填）' : '标题' })
        .width('100%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.titleDraft = value;
          this.recalculateSaveEnabled();
        });

      Row({ space: 10 }) {
        Text(this.hideInnerHeader ? '开始时间（必填）' : '开始时间')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
          .padding({ left: 8, right: 8 });
        Button(this.formatDateTimeLabel(this.startDateDraft, this.startTimeDraft))
          .type(ButtonType.Normal)
          .height(PlanPickerStyle.PANEL_HEIGHT)
          .layoutWeight(1)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .fontSize(PlanPickerStyle.TEXT_FONT_SIZE)
          .fontColor(this.app.theme.palette.textSecondary)
          .onClick(() => {
            this.openStartDateTimeDialog();
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Row({ space: 10 }) {
        Text(this.hideInnerHeader ? '结束时间（必填）' : '结束时间')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
          .padding({ left: 8, right: 8 });
        Button(this.formatDateTimeLabel(this.endDateDraft, this.endTimeDraft))
          .type(ButtonType.Normal)
          .height(PlanPickerStyle.PANEL_HEIGHT)
          .layoutWeight(1)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .fontSize(PlanPickerStyle.TEXT_FONT_SIZE)
          .fontColor(this.app.theme.palette.textSecondary)
          .onClick(() => {
            this.openEndDateTimeDialog();
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      TextInput({ text: this.locationDraft, placeholder: '地点（选填）' })
        .width('100%')
        .height(46)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 9, bottom: 9 })
        .onChange((value: string) => {
          this.locationDraft = value;
          this.recalculateSaveEnabled();
        });

      TextArea({ text: this.descriptionDraft, placeholder: this.hideInnerHeader ? '备注描述（选填）' : '描述（选填）' })
        .width('100%')
        .height(92)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.descriptionDraft = value;
          this.recalculateSaveEnabled();
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
    Column() {
      if (!this.hideInnerHeader && this.resolveEditingPlan() === null) {
        Column({ space: 8 }) {
          Text('未找到日程')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary);
          Text('该日程可能已被删除。')
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary);
        }
        .width('100%')
        .padding({ left: 6, right: 6, top: 8, bottom: 8 });
      } else {
        Scroll() {
          this.buildContent();
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onAppear(() => {
          if (this.hideInnerHeader) {
            return;
          }
          const currentPlan = this.resolveEditingPlan();
          const currentPlanId = currentPlan ? this.normalizeId(currentPlan.id) : 0;
          if (this.loadedPlanId !== currentPlanId) {
            this.loadDraftFromCurrentPlan();
          }
        });
      }
    }
    .width('100%')
    .height('100%');
  }

  aboutToDisappear(): void {
    this.saving = false;
    this.saveEnabled = false;
    this.initialTitle = '';
    this.initialLocation = '';
    this.initialDescription = '';
    this.initialIsCourse = 0;
    this.initialStartMs = 0;
    this.initialEndMs = 0;
    this.loadedPlanId = 0;

    if (this.hideInnerHeader) {
      this.state.closePlanEditor();
      return;
    }
    this.state.closePlanDetail();
  }
}
