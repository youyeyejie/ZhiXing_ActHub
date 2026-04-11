import { AppState, useAppState } from '../../../app/AppStates';
import { AutoSaveText } from '../../../components/form/AutoSaveText';
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

  private resolveNormalizedId(value: string): string {
    return `${value}`.trim();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private closeOverlay(): void {
    this.newCategoryName = '';
    this.applyEditorSelection('');
    this.state.closeCategoryEditor();
  }

  private submitNewCategory(): void {
    const name = this.newCategoryName;
    this.state.addCategory(name)
      .then((ok: boolean) => {
        this.safeToast(ok ? '分类已添加' : '添加失败：请输入不重复的分类名');
        if (ok) {
          this.newCategoryName = '';
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
          color: '#2AC80D'
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
    this.applyEditorSelection(this.resolveNormalizedId(categoryId));
  }

  private isEditorCategorySelected(categoryId: string): boolean {
    const normalizedId = this.resolveNormalizedId(categoryId);
    if (normalizedId.length === 0) {
      return false;
    }
    return this.resolveEditorCurrentCategoryId() === normalizedId;
  }

  @Builder
  private buildCategoryChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .fontSize(13)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildSelectedCategoryEditor() {
    Column({ space: 8 }) {
      if (this.state.categories.length === 0) {
        Text('请先添加分类，再进行编辑。')
          .fontSize(12)
          .fontColor(this.app.theme.palette.textSecondary);
      }

      ForEach(this.state.categories, (item: TodoCategory) => {
        if (this.isEditorCategorySelected(item.id)) {
          Column({ space: 8 }) {
            AutoSaveText({
              label: '名称',
              placeholder: '请输入分类名称',
              initialValue: item.category,
              debounceMs: 500,
              saveOnBlur: true,
              onAutoSave: async (value: string) => {
                await this.state.updateCategoryName(item.id, value);
              }
            });

            Row() {
              Blank().layoutWeight(1);

              if (item.category !== '学习') {
                Button('删除分类')
                  .type(ButtonType.Capsule)
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.surface)
                  .backgroundColor('#EF4444')
                  .borderRadius(999)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .onClick(() => {
                    this.requestRemoveCategory(item);
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
          .width('100%');
        }
      }, (item: TodoCategory) => `${this.resolveNormalizedId(item.id)}_${this.resolveEditorCurrentCategoryId()}_${this.editorSelectionVersion}`);
    }
    .width('100%')
    .padding({ top: 2, bottom: 2 });
  }

  @Builder
  private buildCardContent() {
    Column({ space: 10 }) {
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

      Row({ space: 8 }) {
        TextInput({ text: this.newCategoryName, placeholder: '输入新分类名称' })
          .layoutWeight(1)
          .fontSize(14)
          .height(40)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .onChange((value: string) => {
            this.newCategoryName = value;
          });

        Button('新增')
          .type(ButtonType.Capsule)
          .height(40)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .fontSize(13)
          .padding({ left: 14, right: 14, top: 3, bottom: 3 })
          .onClick(() => {
            this.submitNewCategory();
          });
      }
      .width('100%');

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
          }, (item: TodoCategory) => `${this.resolveNormalizedId(item.id)}_${item.category}_${this.resolveEditorCurrentCategoryId()}_${this.editorSelectionVersion}`);
        }
        .padding({ top: 2, bottom: 2 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%');

      this.buildSelectedCategoryEditor();
    }
    .width('100%')
    .height('100%');
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
        .height('62%')
        .padding({ left: 14, right: 14, top: 14, bottom: 12 })
        .borderRadius(16)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 20, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 8 })
        .onClick(() => {
        });
      }
      .width('100%')
      .height('100%');
    }
  }
}
