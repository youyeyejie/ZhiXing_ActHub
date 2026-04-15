import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { useTodoPageState, TodoPageState } from '../TodoPageState';

/**
 * 待办详情编辑全屏遮罩层。
 * 目标：覆盖整屏并置于最上层，不推动页面与底栏布局。
 */
@ComponentV2
export struct TodoDetailOverlay {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Local private titleDraft: string = '';
  @Local private detailDraft: string = '';
  @Local private loadedTodoId: number = 0;
  @Local private selectedCategoryIdDraft: number = 0;
  @Local private doneDraft: number = -1;

  private titleSaveTimerId: number = -1;
  private detailSaveTimerId: number = -1;

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

  private loadDraftFromCurrentTodo(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      this.loadedTodoId = 0;
      this.titleDraft = '';
      this.detailDraft = '';
      this.selectedCategoryIdDraft = 0;
      this.doneDraft = -1;
      return;
    }
    this.loadedTodoId = this.normalizeId(todo.id);
    this.titleDraft = this.normalizeText(todo.content);
    this.detailDraft = this.normalizeText(todo.detail);
    this.selectedCategoryIdDraft = this.normalizeId(todo.categoryId);
    this.doneDraft = todo.isDone === 1 ? 1 : 0;
  }

  private clearTitleSaveTimer(): void {
    if (this.titleSaveTimerId >= 0) {
      clearTimeout(this.titleSaveTimerId);
      this.titleSaveTimerId = -1;
    }
  }

  private clearDetailSaveTimer(): void {
    if (this.detailSaveTimerId >= 0) {
      clearTimeout(this.detailSaveTimerId);
      this.detailSaveTimerId = -1;
    }
  }

  private scheduleTitleSave(): void {
    this.clearTitleSaveTimer();
    this.titleSaveTimerId = setTimeout(() => {
      this.persistTitleDraft();
    }, 450);
  }

  private scheduleDetailSave(): void {
    this.clearDetailSaveTimer();
    this.detailSaveTimerId = setTimeout(() => {
      this.persistDetailDraft();
    }, 650);
  }

  private persistTitleDraft(): void {
    this.clearTitleSaveTimer();
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    const todoId = this.normalizeId(todo.id);
    if (todoId <= 0) {
      return;
    }
    const nextTitle = this.normalizeText(this.titleDraft);
    const currentTitle = this.normalizeText(todo.content);
    if (nextTitle === currentTitle) {
      return;
    }
    this.state.updateTodoTitle(todoId, nextTitle);
  }

  private persistDetailDraft(): void {
    this.clearDetailSaveTimer();
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    const todoId = this.normalizeId(todo.id);
    if (todoId <= 0) {
      return;
    }
    const nextDetail = this.normalizeText(this.detailDraft);
    const currentDetail = this.normalizeText(todo.detail);
    if (nextDetail === currentDetail) {
      return;
    }
    this.state.updateTodoDetail(todoId, nextDetail);
  }

  private flushDraftSave(): void {
    this.persistTitleDraft();
    this.persistDetailDraft();
  }

  private closeOverlay(): void {
    this.flushDraftSave();
    this.state.closeTodoDetail();
    this.loadedTodoId = 0;
    this.selectedCategoryIdDraft = 0;
    this.doneDraft = -1;
  }

  private resolveCurrentCategoryId(): number {
    const localCategoryId = this.normalizeId(this.selectedCategoryIdDraft);
    if (localCategoryId > 0) {
      return localCategoryId;
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

  private toggleDoneAndSave(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    this.flushDraftSave();
    const nextDone = this.resolveCurrentDone() === 1 ? 0 : 1;
    this.doneDraft = nextDone;
    this.state.toggleDone(todo.id, nextDone === 1);
  }

  private switchCategory(categoryId: number): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    const normalizedCategoryId = this.normalizeId(categoryId);
    if (normalizedCategoryId <= 0) {
      return;
    }
    this.selectedCategoryIdDraft = normalizedCategoryId;
    this.state.updateTodoCategory(this.normalizeId(todo.id), normalizedCategoryId);
  }

  private deleteCurrentTodo(): void {
    const todo = this.resolveEditingTodo();
    if (todo === null) {
      return;
    }
    this.flushDraftSave();
    this.state.closeTodoDetail();
    this.state.requestDeleteTodo(todo.id);
    this.loadedTodoId = 0;
    this.selectedCategoryIdDraft = 0;
    this.doneDraft = -1;
    this.app.nav.back(false);
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
  private buildDetailCard() {
    Column({ space: 14 }) {
      TextInput({ text: this.titleDraft, placeholder: '标题' })
        .width('100%')
        .height(56)
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

      TextArea({ text: this.detailDraft, placeholder: '详情描述' })
        .width('100%')
        .height(128)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.detailDraft = value;
          this.scheduleDetailSave();
        })
        .onBlur(() => {
          this.persistDetailDraft();
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

      Row({ space: 10 }) {
        Button(this.resolveCurrentDone() === 1 ? '标为未完成' : '标为已完成')
          .type(ButtonType.Capsule)
          .layoutWeight(1)
          .height(50)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .fontSize(16)
          .onClick(() => {
            this.toggleDoneAndSave();
          });

        Button('删除')
          .type(ButtonType.Capsule)
          .layoutWeight(1)
          .height(50)
          .backgroundColor(this.app.theme.palette.dangerSurface)
          .fontColor(this.app.theme.palette.danger)
          .fontSize(16)
          .onClick(() => {
            this.deleteCurrentTodo();
          });
      }
      .width('100%')
      .margin({ top: 6 });
    }
    .width('100%');
  }

  build() {
    Column() {
      if (this.resolveEditingTodo() === null) {
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
          this.buildDetailCard();
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onAppear(() => {
          const currentTodo = this.resolveEditingTodo();
          const currentTodoId = currentTodo ? this.normalizeId(currentTodo.id) : 0;
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
    this.flushDraftSave();
    this.clearTitleSaveTimer();
    this.clearDetailSaveTimer();
    this.state.closeTodoDetail();
    this.loadedTodoId = 0;
    this.selectedCategoryIdDraft = 0;
    this.doneDraft = -1;
  }
}
