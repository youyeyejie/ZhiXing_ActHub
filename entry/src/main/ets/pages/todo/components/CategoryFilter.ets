import { AppState, useAppState } from '../../../app/AppStates';
import { ActionSheet, ActionSheetController } from '../../../components/card/ActionSheet';
import { AutoSaveText } from '../../../components/form/AutoSaveText';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { useTodoPageState, TodoPageState } from '../TodoPageState';
import promptAction from '@ohos.promptAction';

interface DialogResult {
  index: number;
}

/**
 * 待办分类筛选骨架。
 * TODO: 后续补充分组排序、批量管理和更细粒度筛选策略。
 */
@ComponentV2
export struct CategoryFilter {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  private sheetController: ActionSheetController = new ActionSheetController();
  @Local private newCategoryName: string = '';
  @Local private editorSelectedCategoryId: string = '';
  @Local private editorSelectionVersion: number = 0;
  @Local private mainSelectedCategoryId: string = '';
  @Local private mainSelectionVersion: number = 0;

  aboutToAppear(): void {
    // 主分类栏默认选中“全部”。
    this.applyMainSelection('');
    this.state.selectCategory('');
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
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
          color: '#FF5500'  // 添加颜色，如灰色
        },
        {
          text: '确认',
          color: '#ff2ac80d'  // 添加颜色，如主题色
        }
      ]
    }).then((result: DialogResult) => {
      if (result.index !== 1) {
        return;
      }
      this.state.removeCategory(categoryId, true)
        .then((ok: boolean) => {
          if (ok) {
            this.safeToast('分类及关联待办已删除');
            if (this.editorSelectedCategoryId === categoryId) {
              this.applyEditorSelection('');
            }
            if (this.mainSelectedCategoryId === categoryId) {
              this.selectMainCategory('');
            }
          } else {
            this.safeToast('删除失败');
          }
        })
        .catch((_error: Error) => {
          this.safeToast('删除失败：数据库异常');
        });
    }).catch((_error: Error) => {
      this.safeToast('弹窗打开失败');
    });
  }

  private resolveNormalizedId(value: string): string {
    return `${value}`.trim();
  }

  private applyMainSelection(categoryId: string): void {
    const normalizedId = this.resolveNormalizedId(categoryId);
    if (this.mainSelectedCategoryId === normalizedId) {
      return;
    }
    this.mainSelectedCategoryId = normalizedId;
    this.mainSelectionVersion = this.mainSelectionVersion + 1;
  }

  private selectMainCategory(categoryId: string): void {
    const normalizedId = this.resolveNormalizedId(categoryId);
    this.applyMainSelection(normalizedId);
    this.state.selectCategory(normalizedId);
  }

  private isMainAllSelected(): boolean {
    return this.resolveNormalizedId(this.mainSelectedCategoryId).length === 0;
  }

  private isMainCategorySelected(categoryId: string): boolean {
    const normalizedId = this.resolveNormalizedId(categoryId);
    if (normalizedId.length === 0) {
      return false;
    }
    return this.resolveNormalizedId(this.mainSelectedCategoryId) === normalizedId;
  }

  private resolveEditorCurrentCategoryId(): string {
    const selectedId = this.resolveNormalizedId(this.editorSelectedCategoryId);
    if (selectedId.length > 0) {
      const exists = this.state.categories.some((item: TodoCategory) => this.resolveNormalizedId(item.id) === selectedId);
      if (exists) {
        return selectedId;
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

  private openCategoryEditorSheet(): void {
    const preferredId = this.resolveNormalizedId(this.mainSelectedCategoryId);
    if (preferredId.length > 0) {
      this.applyEditorSelection(preferredId);
    } else if (this.state.categories.length > 0) {
      this.applyEditorSelection(this.resolveNormalizedId(this.state.categories[0].id));
    } else {
      this.applyEditorSelection('');
    }
    this.state.openCategoryEditor();
  }

  @Builder
  private buildCategoryChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .fontSize(14)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .borderRadius(999)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildCategoryEditorContent() {
    Column({ space: 12 }) {
      Text('编辑分类')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Column({ space: 10 }) {
        TextInput({ text: this.newCategoryName, placeholder: '分类名称' })
          .fontSize(14)
          .width('100%')
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .padding(12)
          .onChange((value: string) => {
            this.newCategoryName = value;
          });

        Button('添加分类')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(44)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .borderRadius(16)
          .onClick(() => {
            this.submitNewCategory();
          });
      }
      .width('100%')
      .padding(12)
      .borderRadius(16)
      .backgroundColor(this.app.theme.palette.surface);

      Text('当前分类')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Scroll() {
        Row({ space: 10 }) {
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
          }, (item: TodoCategory) => `${this.resolveNormalizedId(item.id)}_${this.resolveEditorCurrentCategoryId()}_${this.editorSelectionVersion}_${item.updatedAt}`);
        }
        .padding({ top: 2, bottom: 2 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%');

      Column({ space: 8 }) {
        if (this.state.categories.length === 0) {
          Text('请先添加分类，再进行编辑。')
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary);
        }

        ForEach(this.state.categories, (item: TodoCategory) => {
          if (this.isEditorCategorySelected(item.id)) {
            Column({ space: 10 }) {
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

              Row({ space: 10 }) {
                Text(`当前选中：${item.category}`)
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textSecondary);

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
            .width('100%')
            .padding(12)
            .borderRadius(16)
            .backgroundColor(this.app.theme.palette.surface);
          }
        }, (item: TodoCategory) => `${this.resolveNormalizedId(item.id)}_${item.updatedAt}`);
      }
      .width('100%');

      Blank().height(10);
    }
    .width('100%');
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Text('分类')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        Button('编辑')
          .type(ButtonType.Capsule)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textPrimary)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(999)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.openCategoryEditorSheet();
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Scroll() {
        Row({ space: 10 }) {
          this.buildCategoryChip('全部', this.isMainAllSelected(), () => {
            this.selectMainCategory('');
          });

          ForEach(this.state.categories, (item: TodoCategory) => {
            this.buildCategoryChip(item.category, this.isMainCategorySelected(item.id), () => {
              this.selectMainCategory(this.resolveNormalizedId(item.id));
            });
          }, (item: TodoCategory) => `${this.resolveNormalizedId(item.id)}_${this.mainSelectedCategoryId}_${this.mainSelectionVersion}`);
        }
        .padding({ top: 2, bottom: 2 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%');

      if (this.state.isCategoryEditorVisible) {
        ActionSheet({
          isVisible: true,
          panelHeight: '70%',
          controller: this.sheetController,
          onDismiss: () => {
            this.applyEditorSelection('');
            this.state.closeCategoryEditor();
          }
        }) {
          this.buildCategoryEditorContent();
        }
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
