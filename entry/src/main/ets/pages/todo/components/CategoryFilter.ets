import { AppState, useAppState } from "../../../app/AppStates";
import { TodoCategory } from "../../../core/models/TodoCategory";
import { useTodoPageState, TodoPageState } from "../TodoPageState";

/**
 * 待办分类筛选骨架。
 * TODO: 后续补充分组排序、批量管理和更细粒度筛选策略。
 */
@ComponentV2
export struct CategoryFilter {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();

  aboutToAppear(): void {
    // 主分类栏默认选中“全部”。
    if (this.resolveNormalizedId(this.state.selectedCategoryId) <= 0) {
      this.state.selectCategory(0);
    }
  }

  private resolveNormalizedId(value: number): number {
    return value > 0 ? value : 0;
  }

  private selectMainCategory(categoryId: number): void {
    const normalizedId = this.resolveNormalizedId(categoryId);
    this.state.selectCategory(normalizedId);
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

  private openCategoryEditorOverlay(): void {
    this.state.openCategoryEditor();
  }

  @Builder
  private buildCategoryChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(14)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .backgroundColor(
        selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary,
      )
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  /**
   * 渲染分类筛选占位。
   * TODO: 后续接入分类列表、选中态和筛选回调。
   */
  build() {
    Column({ space: 8 }) {
      Row() {
        Text("分类")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r("sys.symbol.pencil_line_1"))
            .fontSize(16)
            .fontColor([this.app.theme.palette.textPrimary])
        }
        .width(30)
        .height(30)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .onClick(() => {
          this.openCategoryEditorOverlay();
        })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
      Scroll() {
        Row({ space: 10 }) {
          ForEach(
            [this.resolveAllChipRenderToken()],
            (_token: string) => {
              this.buildCategoryChip("全部", this.isMainChipSelected(0), () => {
                this.selectMainCategory(0);
              });
            },
            (token: string) => token,
          )
          ForEach(
            this.state.categories,
            (item: TodoCategory) => {
              this.buildCategoryChip(item.category, this.isMainChipSelected(item.id), () => {
                this.selectMainCategory(this.resolveNormalizedId(item.id));
              });
            },
            (item: TodoCategory) =>
              `${this.resolveNormalizedId(item.id)}_${item.category}_${this.resolveCurrentMainSelectionId()}`,
          )
        }
        .padding({ top: 2, bottom: 2 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width("100%")
    }
    .width("100%")
    .padding(12)
    .borderRadius(18)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
