import { AppState, useAppState } from '../../../app/AppStates';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { useTodoPageState, TodoPageState } from '../TodoPageState';
import promptAction from '@ohos.promptAction';

interface DialogResult {
  index: number;
}

/**
 * 待办分类编辑全屏遮罩层。
 * 目标：覆盖整页、置于顶层，不推动底部内容布局。
 */
@ComponentV2
export struct CategoryEditorOverlay {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Local private newCategoryName: string = '';
  @Local private editorSelectedCategoryId: string = '';
  @Local private editorSelectionVersion: number = 0;
  @Local private editorMode: string = 'none'; // none | create | edit
  @Local private editingCategoryNameDraft: string = '';
  @Local private loadedEditCategoryId: string = '';

  private categoryNameSaveTimerId: number = -1;

  private resolveNormalizedId(value: string): string {
    return `${value}`.trim();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private resolveNormalizedName(value: string): string {
    return `${value}`.trim();
  }

  private clearCategoryNameSaveTimer(): void {
    if (this.categoryNameSaveTimerId >= 0) {
      clearTimeout(this.categoryNameSaveTimerId);
      this.categoryNameSaveTimerId = -1;
    }
  }

  private applyEditCategoryDraft(categoryId: string): void {
    const normalizedId = this.resolveNormalizedId(categoryId);
    if (normalizedId.length === 0) {
      this.loadedEditCategoryId = '';
      this.editingCategoryNameDraft = '';
      return;
    }
    const found = this.state.categories.find((item: TodoCategory) => this.resolveNormalizedId(item.id) === normalizedId);
    if (!found) {
      this.loadedEditCategoryId = '';
      this.editingCategoryNameDraft = '';
      return;
    }
    this.loadedEditCategoryId = normalizedId;
    this.editingCategoryNameDraft = found.category;
  }

  private scheduleEditCategoryNameSave(): void {
    this.clearCategoryNameSaveTimer();
    this.categoryNameSaveTimerId = setTimeout(() => {
      this.persistEditCategoryName();
    }, 500);
  }

  private persistEditCategoryName(): void {
    this.clearCategoryNameSaveTimer();
    const selected = this.resolveSelectedEditorCategory();
    if (selected === null) {
      return;
    }
    const nextName = this.resolveNormalizedName(this.editingCategoryNameDraft);
    const currentName = this.resolveNormalizedName(selected.category);
    if (nextName.length === 0 || nextName === currentName) {
      return;
    }
    this.state.updateCategoryName(selected.id, nextName);
  }

  private closeOverlay(): void {
    this.persistEditCategoryName();
    this.newCategoryName = '';
    this.applyEditorSelection('');
    this.editorMode = 'none';
    this.applyEditCategoryDraft('');
    this.state.closeCategoryEditor();
  }

  private submitNewCategory(): void {
    const name = this.newCategoryName;
    this.state.addCategory(name)
      .then((ok: boolean) => {
        this.safeToast(ok ? '分类已添加' : '添加失败：请输入不重复的分类名');
        if (ok) {
          this.newCategoryName = '';
          this.editorMode = 'none';
          this.applyEditCategoryDraft('');
        }
      })
      .catch((_error: Error) => {
        this.safeToast('添加失败：数据库异常');
      });
  }

  private requestRemoveCategory(category: TodoCategory): void {
    const categoryId = this.resolveNormalizedId(category.id);
    if (categoryId.length === 0) {
      return;
    }
    if (category.category === '学习') {
      this.safeToast('默认分类不可删除');
      return;
    }
    promptAction.showDialog({
      title: '删除分类',
      message: '删除标签时该标签下内容一并删除',
      buttons: [
        {
          text: '取消',
          color: '#FF5500'
        },
        {
          text: '确认',
          color: '#ff2664eb'
        }
      ]
    }).then((result: DialogResult) => {
      if (result.index !== 1) {
        return;
      }
      this.state.removeCategory(categoryId, true)
        .then((ok: boolean) => {
          if (ok && this.resolveNormalizedId(this.editorSelectedCategoryId) === categoryId) {
            this.applyEditorSelection('');
            this.editorMode = 'none';
            this.applyEditCategoryDraft('');
          }
          this.safeToast(ok ? '分类及关联待办已删除' : '删除失败');
        })
        .catch((_error: Error) => {
          this.safeToast('删除失败：数据库异常');
        });
    }).catch((_error: Error) => {
      this.safeToast('弹窗打开失败');
    });
  }

  private resolveEditorCurrentCategoryId(): string {
    const selectedId = this.resolveNormalizedId(this.editorSelectedCategoryId);
    if (selectedId.length > 0) {
      const exists = this.state.categories.some((item: TodoCategory) => this.resolveNormalizedId(item.id) === selectedId);
      if (exists) {
        return selectedId;
      }
    }
    const preferredId = this.resolveNormalizedId(this.state.selectedCategoryId);
    if (preferredId.length > 0) {
      const exists = this.state.categories.some((item: TodoCategory) => this.resolveNormalizedId(item.id) === preferredId);
      if (exists) {
        return preferredId;
      }
    }
    if (this.state.categories.length > 0) {
      return this.resolveNormalizedId(this.state.categories[0].id);
    }
    return '';
  }

  private applyEditorSelection(categoryId: string): void {
    const normalizedId = this.resolveNormalizedId(categoryId);
    if (this.editorSelectedCategoryId === normalizedId) {
      return;
    }
    this.editorSelectedCategoryId = normalizedId;
    this.editorSelectionVersion = this.editorSelectionVersion + 1;
  }

  private selectEditorCategory(categoryId: string): void {
    this.persistEditCategoryName();
    this.applyEditorSelection(this.resolveNormalizedId(categoryId));
    this.editorMode = 'edit';
    this.applyEditCategoryDraft(categoryId);
  }

  private isEditorCategorySelected(categoryId: string): boolean {
    const normalizedId = this.resolveNormalizedId(categoryId);
    if (normalizedId.length === 0) {
      return false;
    }
    return this.editorMode === 'edit' && this.resolveEditorCurrentCategoryId() === normalizedId;
  }

  private openCreateEditor(): void {
    this.persistEditCategoryName();
    if (this.editorMode === 'create') {
      this.editorMode = 'none';
      this.newCategoryName = '';
      this.applyEditorSelection('');
      this.applyEditCategoryDraft('');
      return;
    }
    this.editorMode = 'create';
    this.applyEditorSelection('');
    this.applyEditCategoryDraft('');
  }

  private resolveSelectedEditorCategory(): TodoCategory | null {
    const selectedId = this.resolveEditorCurrentCategoryId();
    if (selectedId.length === 0) {
      return null;
    }
    const found = this.state.categories.find((item: TodoCategory) => this.resolveNormalizedId(item.id) === selectedId);
    return found ? found : null;
  }

  private isEditorExpanded(): boolean {
    return this.editorMode !== 'none';
  }

  private resolveCardHeight(): string {
    if (this.editorMode === 'create') {
      return '32%';
    }
    if (this.editorMode === 'edit') {
      return '28%';
    }
    return '20%';
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
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildCreateEditorPanel() {
    Column({ space: 12 }) {
      Text('输入新分类名称')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);

      Row({ space: 12 }) {
        TextInput({ text: this.newCategoryName, placeholder: '输入新分类名称' })
          .layoutWeight(1)
          .fontSize(14)
          .height(42)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .onChange((value: string) => {
            this.newCategoryName = value;
          });

        Button('确认')
          .type(ButtonType.Capsule)
          .height(42)
          .fontSize(13)
          .fontColor(this.app.theme.palette.surface)
          .backgroundColor(this.app.theme.palette.primary)
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
          .onClick(() => {
            this.submitNewCategory();
          });
      }
      .width('100%');
    }
    .width('100%');
  }

  @Builder
  private buildEditEditorPanel() {
    Column({ space: 12 }) {
      if (this.resolveSelectedEditorCategory() !== null) {
        Row({ space: 12 }) {
          TextInput({ text: this.editingCategoryNameDraft, placeholder: '改动分类名称' })
            .layoutWeight(1)
            .fontSize(14)
            .height(42)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .borderRadius(10)
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .onChange((value: string) => {
              this.editingCategoryNameDraft = value;
              this.scheduleEditCategoryNameSave();
            })
            .onBlur(() => {
              this.persistEditCategoryName();
            });

          if (this.resolveSelectedEditorCategory()!.category !== '学习') {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(16)
                .fontColor([this.app.theme.palette.surface]);
            }
              .width(30)
              .height(30)
              .backgroundColor('#EF4444')
              .onClick(() => {
                this.requestRemoveCategory(this.resolveSelectedEditorCategory()!);
              });
          } else {
            Text('默认分类不可删除')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);
      }
    }
    .width('100%');
  }

  @Builder
  private buildExpandedEditorPanel() {
    if (this.editorMode === 'create') {
      this.buildCreateEditorPanel();
    } else if (this.editorMode === 'edit') {
      this.buildEditEditorPanel();
    }
  }

  @Builder
  private buildCategoryLine() {
    Row({ space: 8 }) {
      Button('+')
        .type(ButtonType.Circle)
        .width(32)
        .height(32)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.surface)
        .backgroundColor(this.app.theme.palette.primary)
        .onClick(() => {
          this.openCreateEditor();
        });

      Scroll() {
        Row({ space: 8 }) {
          if (this.state.categories.length === 0) {
            Text('暂无分类')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }

          ForEach(this.state.categories, (item: TodoCategory) => {
            this.buildCategoryChip(
              item.category,
              this.isEditorCategorySelected(item.id),
              () => {
                this.selectEditorCategory(item.id);
              }
            );
          }, (item: TodoCategory) => `${this.resolveNormalizedId(item.id)}_${item.category}_${this.resolveEditorCurrentCategoryId()}_${this.editorSelectionVersion}_${this.editorMode}`);
        }
        .padding({ top: 2, bottom: 2 });
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off);
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private buildCardContent() {
    Column({ space: this.isEditorExpanded() ? 12 : 8 }) {
      Row() {
        Text('管理分类')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('×')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textSecondary);
        }
        .width(34)
        .height(34)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .onClick(() => {
          this.closeOverlay();
        });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      this.buildCategoryLine();

      this.buildExpandedEditorPanel();
    }
    .width('100%');
  }

  build() {
    if (this.state.isCategoryEditorVisible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.app.theme.palette.mask)
          .opacity(0.45)
          .onClick(() => {
            this.closeOverlay();
          });

        Column() {
          this.buildCardContent();
        }
        .width('86%')
        .height(this.resolveCardHeight())
        .padding({ left: 14, right: 14, top: 14, bottom: this.isEditorExpanded() ? 10 : 8 })
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 20, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 8 })
        .animation({ duration: 220, curve: Curve.EaseOut, playMode: PlayMode.Normal })
        .onClick(() => {
        });
      }
      .width('100%')
      .height('100%');
    }
  }
}
