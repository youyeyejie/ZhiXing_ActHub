import { AppState, useAppState } from "../../../app/AppStates";
import { TodoCategory } from "../../../core/models/TodoCategory";
import { useTodoPageState, TodoPageState } from "../TodoPageState";
import { CategoryCreateContent } from './CategoryCreateContent';
import { CategoryModifyContent } from './CategoryModifyContent';
import promptAction from '@ohos.promptAction';

/**
 * 待办分类筛选栏。
 * 支持横向滑动筛选、长按编辑（删除/保存）与新增分类入口。
 */
@ComponentV2
export struct CategoryFilter {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Local private ignoreNextCategoryTap: boolean = false;

  aboutToAppear(): void {
    // 主分类栏默认选中“全部”。
    if (this.resolveNormalizedId(this.state.selectedCategoryId) <= 0) {
      this.state.selectCategory(0);
    }
  }

  private resolveNormalizedId(value: number): number {
    return value > 0 ? value : 0;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private selectMainCategory(categoryId: number): void {
    const normalizedId = this.resolveNormalizedId(categoryId);
    const currentId = this.resolveCurrentMainSelectionId();
    if (normalizedId > 0 && currentId === normalizedId) {
      this.state.selectCategory(0);
    } else {
      this.state.selectCategory(normalizedId);
    }
  }

  private resolveCurrentMainSelectionId(): number {
    return this.resolveNormalizedId(this.state.selectedCategoryId);
  }

  private isMainChipSelected(categoryId: number): boolean {
    const normalizedId = this.resolveNormalizedId(categoryId);
    return this.resolveCurrentMainSelectionId() === normalizedId;
  }

  private resolveAllChipRenderToken(): string {
    const selectedId = this.resolveCurrentMainSelectionId();
    return selectedId <= 0 ? "__all__selected" : `__all__${selectedId}`;
  }

  private resolveCategoryColor(color: string): string {
    const normalized = `${color}`.trim();
    if (normalized.length > 0) {
      return normalized;
    }
    return this.app.theme.palette.surfaceSecondary;
  }

  private resolveDimmedCategoryColor(color: string): string {
    const normalized = `${color}`.trim();
    if (normalized.length === 7 && normalized[0] === '#') {
      return `#66${normalized.slice(1)}`;
    }
    if (normalized.length === 9 && normalized[0] === '#') {
      return `#66${normalized.slice(3)}`;
    }
    return this.app.theme.palette.surfaceSecondary;
  }

  private resolveCategoryId(category: TodoCategory): number {
    return this.resolveNormalizedId(category.id);
  }

  private isCategorySelected(category: TodoCategory): boolean {
    return this.isMainChipSelected(this.resolveCategoryId(category));
  }

  private resolveCategoryChipBackgroundColor(category: TodoCategory): string {
    if (this.isCategorySelected(category)) {
      return this.resolveCategoryColor(category.color);
    }
    return this.resolveDimmedCategoryColor(category.color);
  }

  private resolveCategoryChipFontColor(category: TodoCategory): string {
    if (this.isCategorySelected(category)) {
      return this.app.theme.palette.surface;
    }
    return this.app.theme.palette.textSecondary;
  }

  private openCreateCategoryActionSheet(): void {
    if (this.state.isCategoryColorCapacityReached()) {
      this.safeToast(`分类数量已达上限（最多 ${this.state.getCategoryColorCapacity()} 个）`);
      return;
    }
    this.state.openCategoryCreate();
    this.app.nav.openActionSheet(this.buildCategoryCreateContent, 'auto');
  }

  private openEditCategoryActionSheet(category: TodoCategory): void {
    const categoryId = this.resolveNormalizedId(category.id);
    if (categoryId <= 0) {
      return;
    }
    this.ignoreNextCategoryTap = true;
    this.state.openCategoryModify(categoryId);
    this.app.nav.openActionSheet(this.buildCategoryModifyContent, 'auto');
  }

  @Builder
  private buildAllChip() {
    Button('全部')
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(14)
      .fontColor(this.isMainChipSelected(0) ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(this.isMainChipSelected(0) ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .border({ width: 0 })
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        this.selectMainCategory(0);
      });
  }

  @Builder
  private buildCategoryChip(category: TodoCategory) {
    Button(category.category)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(14)
      .fontColor(this.resolveCategoryChipFontColor(category))
      .backgroundColor(this.resolveCategoryChipBackgroundColor(category))
      .opacity(1)
      .border({ width: 0 })
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        if (this.ignoreNextCategoryTap) {
          this.ignoreNextCategoryTap = false;
          return;
        }
        this.selectMainCategory(this.resolveCategoryId(category));
      })
      .gesture(
        LongPressGesture({ repeat: false, duration: 350 }).onAction(() => {
          this.openEditCategoryActionSheet(category);
        }),
      );
  }

  @Builder
  private buildCategoryCreateContent() {
    CategoryCreateContent();
  }

  @Builder
  private buildCategoryModifyContent() {
    CategoryModifyContent();
  }

  build() {
    Row({ space: 10 }) {
      Scroll() {
        Row({ space: 10 }) {
          ForEach(
            [this.resolveAllChipRenderToken()],
            (_token: string) => {
              this.buildAllChip();
            },
            (token: string) => token,
          );

          ForEach(
            this.state.categories,
            (item: TodoCategory) => {
              this.buildCategoryChip(item);
            },
            (item: TodoCategory) =>
                `${this.resolveNormalizedId(item.id)}_${item.category}_${this.resolveCurrentMainSelectionId()}`,
          );
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ top: 2, bottom: 2 });
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off);

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(16)
          .fontColor([this.app.theme.palette.surface]);
      }
      .width(30)
      .height(30)
      .backgroundColor(this.app.theme.palette.primary)
      .onClick(() => {
        this.openCreateCategoryActionSheet();
      });
    }
    .width('100%')
    .padding(12)
    .borderRadius(18)
    .alignItems(VerticalAlign.Center);
  }
}
