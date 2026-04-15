import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { useTodoPageState, TodoPageState } from '../TodoPageState';

/**
 * 待办编辑器内容。
 * hideInnerHeader=true 用于新建 ActionSheet，false 用于详情 DetailCard。
 */
@ComponentV2
export struct TodoEditorContent {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Param hideInnerHeader: boolean = false;

  @Local private saving: boolean = false;
  @Local private saveEnabled: boolean = false;
  @Local private titleDraft: string = '';
  @Local private detailDraft: string = '';
  @Local private initialTitle: string = '';
  @Local private initialDetail: string = '';
  @Local private loadedTodoId: string = '';
  @Local private selectedCategoryIdDraft: string = '';
  @Local private initialCategoryId: string = '';
  @Local private doneDraft: number = -1;
  @Local private initialDone: number = 0;

  aboutToAppear(): void {
    if (this.hideInnerHeader) {
      this.prepareDraftForCreate();
      return;
    }
    this.loadDraftFromCurrentTodo();
  }

  private normalizeId(value: string): string {
    return `${value}`.trim();
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
    if (todoId.length === 0) {
      return null;
    }
    const found = this.state.todos.find((item: Todo) => this.normalizeId(item.id) === todoId);
    return found ? found : null;
  }

  private async prepareDraftForCreate(): Promise<void> {
    await this.state.refreshAll();
    this.loadedTodoId = '';
    this.titleDraft = '';
    this.detailDraft = '';
    this.initialTitle = '';
    this.initialDetail = '';
    this.selectedCategoryIdDraft =
      this.state.selectedCategoryId.length > 0
        ? this.normalizeId(this.state.selectedCategoryId)
        : this.normalizeId(this.state.getDefaultCategoryId());
    if (this.selectedCategoryIdDraft.length === 0 && this.state.categories.length > 0) {
      this.selectedCategoryIdDraft = this.normalizeId(this.state.categories[0].id);
    }
    this.initialCategoryId = this.selectedCategoryIdDraft;
    this.doneDraft = 0;
    this.initialDone = 0;
    this.recalculateSaveEnabled();
  }

  private loadDraftFromCurrentTodo(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      this.loadedTodoId = '';
      this.titleDraft = '';
      this.detailDraft = '';
      this.initialTitle = '';
      this.initialDetail = '';
      this.selectedCategoryIdDraft = '';
      this.initialCategoryId = '';
      this.doneDraft = -1;
      this.initialDone = 0;
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
    this.recalculateSaveEnabled();
  }

  private hasDraftChanges(): boolean {
    return this.normalizeText(this.titleDraft) !== this.initialTitle
      || this.normalizeText(this.detailDraft) !== this.initialDetail
      || this.resolveCurrentCategoryId() !== this.initialCategoryId
      || this.resolveCurrentDone() !== this.initialDone;
  }

  private computeCanSave(): boolean {
    if (this.saving) {
      return false;
    }
    if (this.normalizeText(this.titleDraft).length === 0) {
      return false;
    }
    if (this.hideInnerHeader) {
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
    const detail = this.detailDraft;
    const categoryId = this.resolveCurrentCategoryId();
    try {
      const ok = await this.state.createTodo(title, detail, categoryId);
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
    if (todoId.length === 0) {
      return;
    }
    this.saving = true;
    this.recalculateSaveEnabled();
    try {
      await this.state.updateTodoTitle(todoId, this.normalizeText(this.titleDraft));
      await this.state.updateTodoDetail(todoId, this.normalizeText(this.detailDraft));
      await this.state.updateTodoCategory(todoId, this.resolveCurrentCategoryId());
      await this.state.toggleDone(todoId, this.resolveCurrentDone() === 1);

      this.initialTitle = this.normalizeText(this.titleDraft);
      this.initialDetail = this.normalizeText(this.detailDraft);
      this.initialCategoryId = this.resolveCurrentCategoryId();
      this.initialDone = this.resolveCurrentDone();
      this.app.nav.back(false);
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private resolveCurrentCategoryId(): string {
    const localCategoryId = this.normalizeId(this.selectedCategoryIdDraft);
    if (localCategoryId.length > 0) {
      return localCategoryId;
    }
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return '';
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

  private toggleDoneDraft(): void {
    const nextDone = this.resolveCurrentDone() === 1 ? 0 : 1;
    this.doneDraft = nextDone;
    this.recalculateSaveEnabled();
  }

  private switchCategory(categoryId: string): void {
    const normalizedCategoryId = this.normalizeId(categoryId);
    if (normalizedCategoryId.length === 0) {
      return;
    }
    this.selectedCategoryIdDraft = normalizedCategoryId;
    this.recalculateSaveEnabled();
  }

  private canDelete(): boolean {
    if (this.hideInnerHeader || this.saving) {
      return false;
    }
    return this.resolveEditingTodo() !== null;
  }

  private deleteCurrentTodo(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    this.state.closeTodoDetail();
    this.state.requestDeleteTodo(todo.id);
    this.loadedTodoId = '';
    this.selectedCategoryIdDraft = '';
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
        .fontColor([this.app.theme.palette.danger]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.surface)
      .enabled(this.canDelete())
      .onClick(() => {
        this.deleteCurrentTodo();
      });
  }

  @Builder
  private buildCategoryChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(13)
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
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text(this.hideInnerHeader ? '新增待办' : '编辑待办')
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

      TextInput({ text: this.titleDraft, placeholder: '标题' })
        .width('100%')
        .height(56)
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

      TextArea({ text: this.detailDraft, placeholder: this.hideInnerHeader ? '请输入待办详情（选填）' : '详情描述' })
        .width('100%')
        .height(128)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.detailDraft = value;
          this.recalculateSaveEnabled();
        });

      Scroll() {
        Row({ space: 8 }) {
          if (this.state.categories.length === 0) {
            Text('暂无分类')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }

          ForEach(this.state.categories, (cat: TodoCategory) => {
            this.buildCategoryChip(
              cat.category,
              this.resolveCurrentCategoryId() === this.normalizeId(cat.id),
              () => {
                this.switchCategory(this.normalizeId(cat.id));
              }
            );
          }, (cat: TodoCategory) => `${this.normalizeId(cat.id)}_${this.resolveCurrentCategoryId()}`);
        }
        .padding({ top: 2, bottom: 2 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ top: 2, bottom: 6 });

      if (!this.hideInnerHeader) {
        Row({ space: 10 }) {
          Button(this.resolveCurrentDone() === 1 ? '标为未完成' : '标为已完成')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(50)
            .backgroundColor(this.app.theme.palette.primary)
            .fontColor(this.app.theme.palette.surface)
            .fontSize(16)
            .onClick(() => {
              this.toggleDoneDraft();
            });
        }
        .width('100%')
        .margin({ top: 6 });
      }
    }
    .width('100%');
  }

  build() {
    Column() {
      if (!this.hideInnerHeader && this.resolveEditingTodo() === null) {
        Column({ space: 8 }) {
          Text('未找到待办')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary);
          Text('该待办可能已被删除。')
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
          const currentTodo = this.resolveEditingTodo();
          const currentTodoId = currentTodo ? this.normalizeId(currentTodo.id) : '';
          if (this.loadedTodoId !== currentTodoId) {
            this.loadDraftFromCurrentTodo();
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
    this.initialDetail = '';
    this.initialCategoryId = '';
    this.initialDone = 0;
    this.loadedTodoId = '';
    this.selectedCategoryIdDraft = '';
    this.doneDraft = -1;

    if (this.hideInnerHeader) {
      this.state.closeTodoEditor();
      return;
    }
    this.state.closeTodoDetail();
  }
}
