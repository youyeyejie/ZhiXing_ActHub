import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { useTodoPageState, TodoPageState } from '../TodoPageState';
import { CategoryCreateContent } from './CategoryCreateContent';
import { FormTypography } from '../../../core/theme/FormTypography';
import promptAction from '@ohos.promptAction';
import { PlanPickerStyle } from '../../plan/components/PlanPickerStyle';

const TODO_DUE_DATE_START_MS = new Date(2000, 0, 1).getTime();
const TODO_DUE_DATE_END_MS = new Date(2100, 11, 31, 23, 59, 59, 999).getTime();

/**
 * 待办编辑器内容。
 * isForCreate=true 用于新建 ActionSheet，false 用于详情 DetailCard。
 */
@ComponentV2
export struct TodoEditorContent {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Param isForCreate: boolean = false;

  @Local private saving: boolean = false;
  @Local private saveEnabled: boolean = false;
  @Local private titleDraft: string = '';
  @Local private detailDraft: string = '';
  @Local private initialTitle: string = '';
  @Local private initialDetail: string = '';
  @Local private loadedTodoId: number = 0;
  @Local private selectedCategoryIdDraft: number = -1;
  @Local private initialCategoryId: number = 0;
  @Local private doneDraft: number = -1;
  @Local private initialDone: number = 0;
  @Local private priorityDraft: number = 0;
  @Local private initialPriority: number = 0;
  @Local private dueAtDraft: number = 0;
  @Local private initialDueAt: number = 0;

  aboutToAppear(): void {
    if (this.isForCreate) {
      this.prepareDraftForCreate();
      return;
    }
    this.loadDraftFromCurrentTodo();
  }

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private resolveEditingTodo(): Todo | null {
    const todoId = this.normalizeId(this.state.editingTodoId);
    if (todoId <= 0) {
      return null;
    }
    const found = this.state.todos.find((item: Todo) => this.normalizeId(item.id) === todoId);
    return found ? found : null;
  }

  private async prepareDraftForCreate(): Promise<void> {
    await this.state.refreshAll();
    this.loadedTodoId = 0;
    this.titleDraft = '';
    this.detailDraft = '';
    this.initialTitle = '';
    this.initialDetail = '';
    const selectedCategoryId = this.normalizeId(this.state.selectedCategoryId);
    const selectedCategoryExists = selectedCategoryId > 0
      && this.state.categories.some((item: TodoCategory) => this.normalizeId(item.id) === selectedCategoryId);
    this.selectedCategoryIdDraft = selectedCategoryExists ? selectedCategoryId : 0;
    this.initialCategoryId = this.selectedCategoryIdDraft;
    this.doneDraft = 0;
    this.initialDone = 0;
    this.priorityDraft = 0;
    this.initialPriority = 0;
    this.dueAtDraft = 0;
    this.initialDueAt = 0;
    this.recalculateSaveEnabled();
  }

  private loadDraftFromCurrentTodo(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      this.loadedTodoId = 0;
      this.titleDraft = '';
      this.detailDraft = '';
      this.initialTitle = '';
      this.initialDetail = '';
      this.selectedCategoryIdDraft = -1;
      this.initialCategoryId = 0;
      this.doneDraft = -1;
      this.initialDone = 0;
      this.priorityDraft = 0;
      this.initialPriority = 0;
      this.dueAtDraft = 0;
      this.initialDueAt = 0;
      this.recalculateSaveEnabled();
      return;
    }
    this.loadedTodoId = this.normalizeId(todo.id);
    this.titleDraft = this.normalizeText(todo.content);
    this.detailDraft = this.normalizeText(todo.detail);
    this.initialTitle = this.titleDraft;
    this.initialDetail = this.detailDraft;
    this.selectedCategoryIdDraft = this.normalizeId(todo.categoryId);
    this.initialCategoryId = this.selectedCategoryIdDraft;
    this.doneDraft = todo.isDone === 1 ? 1 : 0;
    this.initialDone = this.doneDraft;
    this.priorityDraft = this.normalizePriority(todo.priority);
    this.initialPriority = this.priorityDraft;
    this.dueAtDraft = this.normalizeDueAt(todo.dueAt);
    this.initialDueAt = this.dueAtDraft;
    this.recalculateSaveEnabled();
  }

  private hasDraftChanges(): boolean {
    return this.normalizeText(this.titleDraft) !== this.initialTitle
      || this.normalizeText(this.detailDraft) !== this.initialDetail
      || this.resolveCurrentCategoryId() !== this.initialCategoryId
      || this.resolveCurrentDone() !== this.initialDone
      || this.resolveCurrentPriority() !== this.initialPriority
      || this.resolveCurrentDueAt() !== this.initialDueAt;
  }

  private computeCanSave(): boolean {
    if (this.saving) {
      return false;
    }
    if (this.normalizeText(this.titleDraft).length === 0) {
      return false;
    }
    if (this.isForCreate) {
      return true;
    }
    return this.resolveEditingTodo() !== null;
  }

  private recalculateSaveEnabled(): void {
    this.saveEnabled = this.computeCanSave();
  }

  private async submit(): Promise<void> {
    if (!this.computeCanSave()) {
      this.recalculateSaveEnabled();
      return;
    }
    if (this.isForCreate) {
      await this.submitCreate();
      return;
    }
    await this.submitEdit();
  }

  private async submitCreate(): Promise<void> {
    this.saving = true;
    this.recalculateSaveEnabled();
    const title = this.normalizeText(this.titleDraft);
    const detail = this.detailDraft;
    const categoryId = this.resolveCurrentCategoryId();
    try {
      const ok = await this.state.createTodo(
        title,
        detail,
        categoryId,
        this.resolveCurrentPriority(),
        this.resolveCurrentDueAt(),
      );
      if (ok) {
        this.state.closeTodoEditor();
        this.app.nav.back(false);
      }
    } catch (_error) {
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private async submitEdit(): Promise<void> {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    if (!this.hasDraftChanges()) {
      this.app.nav.back(false);
      return;
    }
    const todoId = this.normalizeId(todo.id);
    if (todoId <= 0) {
      return;
    }
    this.saving = true;
    this.recalculateSaveEnabled();
    try {
      await this.state.updateTodoTitle(todoId, this.normalizeText(this.titleDraft));
      await this.state.updateTodoDetail(todoId, this.normalizeText(this.detailDraft));
      await this.state.updateTodoCategory(todoId, this.resolveCurrentCategoryId());
      await this.state.updateTodoPriority(todoId, this.resolveCurrentPriority());
      await this.state.updateTodoDueAt(todoId, this.resolveCurrentDueAt());
      await this.state.toggleDone(todoId, this.resolveCurrentDone() === 1);

      this.initialTitle = this.normalizeText(this.titleDraft);
      this.initialDetail = this.normalizeText(this.detailDraft);
      this.initialCategoryId = this.resolveCurrentCategoryId();
      this.initialDone = this.resolveCurrentDone();
      this.initialPriority = this.resolveCurrentPriority();
      this.initialDueAt = this.resolveCurrentDueAt();
      this.app.nav.back(false);
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private resolveCurrentCategoryId(): number {
    if (this.selectedCategoryIdDraft >= 0) {
      return this.normalizeId(this.selectedCategoryIdDraft);
    }
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return 0;
    }
    return this.normalizeId(todo.categoryId);
  }

  private resolveCurrentDone(): number {
    if (this.doneDraft === 0 || this.doneDraft === 1) {
      return this.doneDraft;
    }
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return 0;
    }
    return todo.isDone === 1 ? 1 : 0;
  }

  private normalizePriority(value: number): number {
    if (value < 0) {
      return 0;
    }
    if (value > 3) {
      return 3;
    }
    return value;
  }

  private resolveCurrentPriority(): number {
    return this.normalizePriority(this.priorityDraft);
  }

  private normalizeDueAt(value: number): number {
    return value > 0 ? value : 0;
  }

  private resolveCurrentDueAt(): number {
    return this.normalizeDueAt(this.dueAtDraft);
  }

  private switchPriority(priority: number): void {
    const normalizedPriority = this.normalizePriority(priority);
    if (this.resolveCurrentPriority() === normalizedPriority) {
      this.priorityDraft = 0;
    } else {
      this.priorityDraft = normalizedPriority;
    }
    this.recalculateSaveEnabled();
  }

  private clearDueAt(): void {
    this.dueAtDraft = 0;
    this.recalculateSaveEnabled();
  }

  private resolvePriorityLabel(priority: number): string {
    switch (this.normalizePriority(priority)) {
      case 3:
        return '高';
      case 2:
        return '中';
      case 1:
        return '低';
      default:
        return '未设置';
    }
  }

  private resolvePriorityColor(priority: number): string {
    switch (this.normalizePriority(priority)) {
      case 3:
        return this.app.theme.palette.danger;
      case 2:
        return this.app.theme.palette.accentAmber;
      case 1:
        return this.app.theme.palette.info;
      default:
        return this.app.theme.palette.surfaceSecondary;
    }
  }

  private formatDueAt(dueAt: number): string {
    const normalizedDueAt = this.normalizeDueAt(dueAt);
    if (normalizedDueAt <= 0) {
      return '未设置';
    }
    const date: Date = new Date(normalizedDueAt);
    const year: string = `${date.getFullYear()}`;
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private toDueAtValue(date: Date): number {
    const nextDate = new Date(date.getTime());
    nextDate.setHours(23, 59, 0, 0);
    return nextDate.getTime();
  }

  private openDueAtDialog(): void {
    const selectedDate = this.resolveCurrentDueAt() > 0
      ? new Date(this.resolveCurrentDueAt())
      : new Date();
    try {
      this.getUIContext().showDatePickerDialog({
        start: new Date(PlanPickerStyle.DATE_RANGE_START),
        end: new Date(PlanPickerStyle.DATE_RANGE_END),
        selected: selectedDate,
        showTime: false,
        disappearTextStyle: {
          font: { size: PlanPickerStyle.DISAPPEAR_FONT_SIZE, weight: FontWeight.Regular }
        },
        textStyle: {
          font: { size: PlanPickerStyle.TEXT_FONT_SIZE, weight: FontWeight.Regular }
        },
        selectedTextStyle: {
          font: { size: PlanPickerStyle.SELECTED_FONT_SIZE, weight: FontWeight.Medium }
        },
        onDateAccept: (value: Date) => {
          this.dueAtDraft = this.toDueAtValue(value);
          this.recalculateSaveEnabled();
        }
      });
    } catch (_error) {
    }
  }

  private async toggleDoneAndPersist(): Promise<void> {
    if (!this.canToggleDone()) {
      return;
    }
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    const todoId = this.normalizeId(todo.id);
    if (todoId <= 0) {
      return;
    }

    const nextDone = this.resolveCurrentDone() === 1 ? 0 : 1;
    this.doneDraft = nextDone;
    this.saving = true;
    this.recalculateSaveEnabled();
    try {
      await this.state.toggleDone(todoId, nextDone === 1);
      this.initialDone = nextDone;
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private switchCategory(categoryId: number): void {
    const normalizedCategoryId = this.normalizeId(categoryId);
    const currentCategoryId = this.resolveCurrentCategoryId();
    if (currentCategoryId === normalizedCategoryId) {
      this.selectedCategoryIdDraft = 0;
    } else {
      this.selectedCategoryIdDraft = normalizedCategoryId;
    }
    this.recalculateSaveEnabled();
  }

  private resolveCategoryChipColor(color: string): string {
    const normalized = this.normalizeText(color);
    if (normalized.length > 0) {
      return normalized;
    }
    return this.app.theme.palette.surfaceSecondary;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private openCreateCategoryActionSheet(): void {
    if (this.state.isCategoryColorCapacityReached()) {
      this.safeToast(`分类数量已达上限（最多 ${this.state.getCategoryColorCapacity()} 个）`);
      return;
    }
    this.app.nav.openActionSheet(this.buildCreateCategorySheetContent, 'auto');
  }

  private canDelete(): boolean {
    if (this.isForCreate || this.saving) {
      return false;
    }
    return this.resolveEditingTodo() !== null;
  }

  private canToggleDone(): boolean {
    if (this.isForCreate || this.saving) {
      return false;
    }
    return this.resolveEditingTodo() !== null;
  }

  private runTodoListMutationAnimation(action: () => void): void {
    animateTo({ duration: 180, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
      action();
    });
  }

  private deleteCurrentTodo(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    this.state.closeTodoDetail();
    this.runTodoListMutationAnimation(() => {
      this.state.requestDeleteTodo(todo.id);
    });
    this.loadedTodoId = 0;
    this.selectedCategoryIdDraft = 0;
    this.doneDraft = -1;
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
        .fontColor([this.app.theme.palette.surface]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.danger)
      .enabled(this.canDelete())
      .onClick(() => {
        this.deleteCurrentTodo();
      });
  }

  @Builder
  private buildDoneToggleButton() {
    Button({ type: ButtonType.Circle }) {
      if (this.resolveCurrentDone() === 1) {
        SymbolGlyph($r('sys.symbol.checkmark_square'))
          .fontSize(18)
          .fontColor([this.app.theme.palette.surface]);
      } else {
        SymbolGlyph($r('sys.symbol.square_slash'))
          .fontSize(18)
          .fontColor([this.app.theme.palette.surface]);
      }
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.info)
      .enabled(this.canToggleDone())
      .onClick(() => {
        this.runTodoListMutationAnimation(() => {
          this.toggleDoneAndPersist();
        });
      });
  }

  @Builder
  private buildCategoryChip(label: string, color: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(FormTypography.LABEL_SIZE)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(selected ? this.resolveCategoryChipColor(color) : this.app.theme.palette.surfaceSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildMetaChip(label: string, selected: boolean, color: string, onTap: () => void) {
    Button({ type: ButtonType.Capsule }) {
      Text(label)
        .fontSize(FormTypography.LABEL_SIZE)
        .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
    }
      .stateEffect(true)
      .height(30)
      .backgroundColor(selected ? color : this.app.theme.palette.surfaceSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  private resolvePriorityChipLabel(priority: number): string {
    switch (priority) {
      case 1:
        return '低';
      case 2:
        return '中';
      case 3:
        return '高';
      default:
        return '';
    }
  }

  @Builder
  private buildPriorityChip(priority: number, label: string) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(FormTypography.LABEL_SIZE)
      .fontColor(
        this.resolveCurrentPriority() === priority
          ? this.app.theme.palette.surface
          : this.app.theme.palette.textSecondary
      )
      .backgroundColor(
        this.resolveCurrentPriority() === priority
          ? this.resolvePriorityColor(priority)
          : this.app.theme.palette.surfaceSecondary
      )
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        this.switchPriority(priority);
      });
  }

  @Builder
  private buildDueDateFieldButton() {
    Button(this.formatDueAt(this.resolveCurrentDueAt()))
      .type(ButtonType.Normal)
      .height(44)
      .layoutWeight(1)
      .fontSize(FormTypography.INPUT_CONTENT_SIZE)
      .fontColor(this.resolveCurrentDueAt() > 0
        ? this.app.theme.palette.textPrimary
        : this.app.theme.palette.textTertiary)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)
      .borderRadius(12)
      .onClick(() => {
        this.openDueAtDialog();
      });
  }

  @Builder
  private buildClearDueAtButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.delete_left'))
        .fontSize(16)
        .fontColor([this.app.theme.palette.textSecondary]);
    }
      .width(32)
      .height(32)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)
      .onClick(() => {
        this.clearDueAt();
      });
  }

  @Builder
  private buildAddCategoryChip() {
    Button('+')
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.app.theme.palette.textSecondary)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        this.openCreateCategoryActionSheet();
      });
  }

  @Builder
  private buildCreateCategorySheetContent() {
    CategoryCreateContent();
  }

  @Builder
  private buildContent() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text(this.isForCreate ? '新增待办' : '编辑待办')
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        if (!this.isForCreate) {
          this.buildDeleteButton();
          this.buildDoneToggleButton();
        }
        this.buildSaveButton();
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      TextInput({ text: this.titleDraft, placeholder: '待办标题' })
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
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

      TextArea({ text: this.detailDraft, placeholder: '待办详情（选填）' })
        .width('100%')
        .height(128)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.detailDraft = value;
          this.recalculateSaveEnabled();
        });

      Row({ space: 8 }) {
        Text('分类')
          .fontSize(FormTypography.LABEL_SIZE)
          .fontColor(this.app.theme.palette.textSecondary)
          .padding({ left: 8, right: 8 });

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.state.categories, (cat: TodoCategory) => {
              this.buildCategoryChip(
                cat.category,
                cat.color,
                this.resolveCurrentCategoryId() === this.normalizeId(cat.id),
                () => {
                  this.switchCategory(this.normalizeId(cat.id));
                }
              );
            }, (cat: TodoCategory) => `${this.normalizeId(cat.id)}_${this.resolveCurrentCategoryId()}`);

            this.buildAddCategoryChip();
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .padding({ right: 4 });
        }
        .layoutWeight(1)
        .align(Alignment.Start)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off);
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 2, bottom: 2 });

      Row({ space: 8 }) {
        Text('优先级')
          .fontSize(FormTypography.LABEL_SIZE)
          .fontColor(this.app.theme.palette.textSecondary)
          .padding({ left: 8, right: 8 });

        Row({ space: 8 }) {
          ForEach([1, 2, 3], (priority: number) => {
            this.buildPriorityChip(priority, this.resolvePriorityChipLabel(priority));
          }, (priority: number) => `${priority}_${this.resolveCurrentPriority()}`)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Row({ space: 10 }) {
        Text('截止日期')
          .fontSize(FormTypography.LABEL_SIZE)
          .fontColor(this.app.theme.palette.textSecondary)
          .padding({ left: 8, right: 8 });

        this.buildDueDateFieldButton()

        if (this.resolveCurrentDueAt() > 0) {
          this.buildClearDueAtButton()
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .onAppear(() => {
      if (this.isForCreate) {
        return;
      }
      const currentTodo = this.resolveEditingTodo();
      const currentTodoId = currentTodo ? this.normalizeId(currentTodo.id) : 0;
      if (this.loadedTodoId !== currentTodoId) {
        this.loadDraftFromCurrentTodo();
      }
    });
  }

  build() {
    this.buildContent();
  }

  aboutToDisappear(): void {
    this.saving = false;
    this.saveEnabled = false;
    this.initialTitle = '';
    this.initialDetail = '';
    this.initialCategoryId = 0;
    this.initialDone = 0;
    this.initialPriority = 0;
    this.initialDueAt = 0;
    this.loadedTodoId = 0;
    this.selectedCategoryIdDraft = -1;
    this.doneDraft = -1;
    this.priorityDraft = 0;
    this.dueAtDraft = 0;

    if (this.isForCreate) {
      this.state.closeTodoEditor();
      return;
    }
    this.state.closeTodoDetail();
  }
}
