import { AppState, useAppState } from "../../../app/AppStates";
import { TodoCategory } from "../../../core/models/TodoCategory";
import { useTodoPageState, TodoPageState } from "../TodoPageState";
import promptAction from "@ohos.promptAction";

/**
 * 待办新建/编辑半屏页骨架。
 * TODO: 后续补充截止时间、提醒等扩展字段。
 */
@ComponentV2
export struct TodoEditorSheet {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();

  @Local private draftTitle: string = "";
  @Local private draftDetail: string = "";
  @Local private draftCategoryId: string = "";

  aboutToAppear(): void {
    this.prepareDraftForCreate();
  }

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {}
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
  }

  private submit(): void {
    const title = this.draftTitle;
    const detail = this.draftDetail;
    const categoryId = this.draftCategoryId;
    this.state
      .createTodo(title, detail, categoryId)
      .then((ok: boolean) => {
        if (ok) {
          this.close();
          this.safeToast("待办已添加");
        } else {
          this.safeToast("添加失败：请填写标题");
        }
      })
      .catch((_error: object) => {
        this.safeToast("添加失败：数据库异常 " + `${_error}`);
      });
  }

  private close(): void {
    this.state.closeTodoEditor();
    this.draftTitle = "";
    this.draftDetail = "";
    this.app.nav.back(false);
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
  private buildContent() {
    Column({ space: 12 }) {
      Row() {
        Text("新增待办")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Button("完成")
          .type(ButtonType.Capsule)
          .height(40)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .onClick(() => {
            this.submit();
          })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
      TextInput({ text: this.draftTitle, placeholder: "请输入待办标题" })
        .fontSize(14)
        .width("100%")
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftTitle = value;
        })
      TextArea({ text: this.draftDetail, placeholder: "请输入待办详情（选填）" })
        .fontSize(14)
        .width("100%")
        .height(112)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftDetail = value;
        })
      Text("分类")
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
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
      Text("提示：右滑待办可进入专注；左滑删除并支持 5 秒撤销。")
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary)
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
