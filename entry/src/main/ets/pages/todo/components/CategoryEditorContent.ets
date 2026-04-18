import { AppState, useAppState } from '../../../app/AppStates';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { FormTypography } from '../../../core/theme/FormTypography';
import { useTodoPageState, TodoPageState } from '../TodoPageState';
import promptAction from '@ohos.promptAction';

/**
 * 分类编辑器内容。
 * isForCreate=true 用于新建 ActionSheet，false 用于分类修改场景。
 */
@ComponentV2
export struct CategoryEditorContent {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Param isForCreate: boolean = true;

  @Local private categoryName: string = '';
  @Local private saving: boolean = false;
  @Local private loadedCategoryId: number = -1;

  aboutToAppear(): void {
    this.syncDraftFromEditingCategory();
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

  private resolveEffectiveEditingCategoryId(): number {
    if (this.isForCreate) {
      return 0;
    }
    return this.normalizeId(this.state.editingCategoryId);
  }

  private resolveEditingCategory(): TodoCategory | null {
    const editingCategoryId = this.resolveEffectiveEditingCategoryId();
    if (editingCategoryId <= 0) {
      return null;
    }
    const found = this.state.categories.find(
      (item: TodoCategory) => this.normalizeId(item.id) === editingCategoryId,
    );
    return found ? found : null;
  }

  private syncDraftFromEditingCategory(): void {
    const currentCategoryId = this.resolveEffectiveEditingCategoryId();
    if (this.loadedCategoryId === currentCategoryId) {
      return;
    }
    this.loadedCategoryId = currentCategoryId;

    const editingCategory = this.resolveEditingCategory();
    if (editingCategory === null) {
      this.categoryName = '';
      return;
    }
    this.categoryName = this.normalizeText(editingCategory.category);
  }

  private canSubmit(): boolean {
    if (this.saving) {
      return false;
    }
    const trimmed = this.normalizeText(this.categoryName);
    if (trimmed.length === 0) {
      return false;
    }

    if (this.isForCreate) {
      return true;
    }

    const editingCategory = this.resolveEditingCategory();
    if (editingCategory === null) {
      return false;
    }
    return this.normalizeText(editingCategory.category) !== trimmed;
  }

  private canDelete(): boolean {
    if (this.isForCreate || this.saving) {
      return false;
    }
    return this.resolveEditingCategory() !== null;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private async submit(): Promise<void> {
    if (!this.canSubmit()) {
      return;
    }

    if (this.isForCreate && this.state.isCategoryColorCapacityReached()) {
      this.safeToast(`分类数量已达上限（最多 ${this.state.getCategoryColorCapacity()} 个）`);
      return;
    }

    this.saving = true;
    const nextName = this.normalizeText(this.categoryName);
    try {
      if (!this.isForCreate) {
        const editingCategory = this.resolveEditingCategory();
        if (editingCategory === null) {
          this.safeToast('保存失败：分类不存在');
          return;
        }

        const ok = await this.state.updateCategoryName(this.normalizeId(editingCategory.id), nextName);
        if (!ok) {
          this.safeToast('保存失败：分类名重复或分类不存在');
          return;
        }
        this.safeToast('分类已更新');
        this.app.nav.back(false);
        return;
      }

      const ok = await this.state.addCategory(nextName);
      if (!ok) {
        this.safeToast('保存失败：名称重复或数量已达上限');
        return;
      }
      this.safeToast('分类已添加');
      this.app.nav.back(false);
    } catch (_error) {
      this.safeToast('保存失败：数据库异常');
    } finally {
      this.saving = false;
    }
  }

  private async removeCurrentCategory(): Promise<void> {
    if (!this.canDelete()) {
      return;
    }
    const editingCategory = this.resolveEditingCategory();
    if (editingCategory === null) {
      return;
    }
    const editingCategoryId = this.normalizeId(editingCategory.id);

    this.saving = true;
    try {
      const ok = await this.state.removeCategory(editingCategoryId, false);
      if (!ok) {
        this.safeToast('删除失败');
        return;
      }
      this.safeToast('分类已删除，关联待办已改为无分类');
      this.app.nav.back(false);
    } catch (_error) {
      this.safeToast('删除失败：数据库异常');
    } finally {
      this.saving = false;
    }
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
      .enabled(this.canSubmit())
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
        this.removeCurrentCategory();
      });
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Text(this.isForCreate ? '新建分类' : '编辑分类')
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        if (!this.isForCreate) {
          this.buildDeleteButton();
        }
        this.buildSaveButton();
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      TextInput({ text: this.categoryName, placeholder: '输入分类名称' })
        .width('100%')
        .height(44)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(10)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onChange((value: string) => {
          this.categoryName = value;
        });
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 6, bottom: 8 })
    .onAppear(() => {
      this.syncDraftFromEditingCategory();
    });
  }

  aboutToDisappear(): void {
    this.loadedCategoryId = -1;
    this.saving = false;
    this.categoryName = '';
    this.state.openCategoryCreate();
  }
}