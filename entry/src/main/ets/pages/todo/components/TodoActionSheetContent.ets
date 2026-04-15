import { AppState, useAppState } from "../../../app/AppStates";
import { TodoCategory } from "../../../core/models/TodoCategory";
import { useTodoPageState, TodoPageState } from "../TodoPageState";

/**
 * 待办新建表单内容。
 * 作为内容区传入 ActionSheetOverlayDestination，不在此重复实现弹层容器。
 * TODO: 后续补充截止时间、提醒等扩展字段。
 */
@ComponentV2
export struct TodoActionSheetContent {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  @Local private saving: boolean = false;
  @Local private saveEnabled: boolean = false;

  @Local private draftTitle: string = "";
  @Local private draftDetail: string = "";
  @Local private draftCategoryId: string = "";

  aboutToAppear(): void {
    this.prepareDraftForCreate();
  }

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === "undefined" || text === "null") {
      return "";
    }
    return text;
  }

  private async prepareDraftForCreate(): Promise<void> {
    await this.state.refreshAll();
    this.draftTitle = "";
    this.draftDetail = "";
    this.draftCategoryId =
      this.state.selectedCategoryId.length > 0
        ? this.normalizeId(this.state.selectedCategoryId)
        : this.normalizeId(this.state.getDefaultCategoryId());
    if (this.draftCategoryId.length === 0 && this.state.categories.length > 0) {
      this.draftCategoryId = this.normalizeId(this.state.categories[0].id);
    }
    this.recalculateSaveEnabled();
  }

  private recalculateSaveEnabled(): void {
    this.saveEnabled = this.computeCanSave();
  }

  private async submit(): Promise<void> {
    if (!this.computeCanSave()) {
      this.recalculateSaveEnabled();
      return;
    }
    this.saving = true;
    this.recalculateSaveEnabled();
    const title = this.normalizeText(this.draftTitle);
    const detail = this.draftDetail;
    const categoryId = this.draftCategoryId;
    try {
      const ok = await this.state.createTodo(title, detail, categoryId);
      if (ok) {
        this.close();
      }
    } catch (_error) {
    } finally {
      this.saving = false;
      this.recalculateSaveEnabled();
    }
  }

  private close(): void {
    this.state.closeTodoEditor();
    this.draftTitle = "";
    this.draftDetail = "";
    this.app.nav.back(false);
  }

  private computeCanSave(): boolean {
    return !this.saving && this.normalizeText(this.draftTitle).length > 0;
  }

  @Builder
  private buildTagChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .height(28)
      .fontSize(12)
      .backgroundColor(
        selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary,
      )
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildHeaderActionButton(icon: Resource, enabled: boolean, onTap: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: enabled }) {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor([enabled ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary]);
    }
      .width(34)
      .height(34)
      .backgroundColor(enabled ? this.app.theme.palette.primary : this.app.theme.palette.border)
      .opacity(enabled ? 1 : 0.56)
      .onClick(() => {
        if (!enabled) {
          return;
        }
        onTap();
      });
  }

  @Builder
  private buildContent() {
    Column({ space: 12 }) {
      Row() {
        Text("新增待办")
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)

        if (this.saveEnabled) {
          this.buildHeaderActionButton($r("sys.symbol.save"), true, () => {
            this.submit();
          });
        } else {
          this.buildHeaderActionButton($r("sys.symbol.save"), false, () => {
            this.submit();
          });
        }
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      TextInput({ text: this.draftTitle, placeholder: "请输入待办标题" })
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .width("100%")
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftTitle = value;
          this.recalculateSaveEnabled();
        })

      TextArea({ text: this.draftDetail, placeholder: "请输入待办详情（选填）" })
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .width("100%")
        .height(112)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftDetail = value;
          this.recalculateSaveEnabled();
        })

      Scroll() {
        Row({ space: 10 }) {
          if (this.state.categories.length === 0) {
            Text("暂无分类（默认应有“学习”），请先在上方分类区域添加")
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }
          ForEach(
            this.state.categories,
            (cat: TodoCategory) => {
              this.buildTagChip(
                cat.category,
                this.normalizeId(this.draftCategoryId) === this.normalizeId(cat.id),
                () => {
                  this.draftCategoryId = this.normalizeId(cat.id);
                },
              );
            },
            (cat: TodoCategory) =>
              `${this.normalizeId(cat.id)}_${this.normalizeId(this.draftCategoryId)}`,
          )
        }
        .padding({ top: 2, bottom: 2 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width("100%")

    }.width("100%");
  }

  build() {
    Column() {
      this.buildContent()
    }
    .width("100%")
    .height("100%");
  }
}
