import { Idea } from "../../../core/models/Idea";
import { IdeaRepository } from "../../../core/repositories/IdeaRepository";
import { AppState, useAppState } from "../../../app/AppStates";
import promptAction from "@ohos.promptAction";
import { IdeaPageState, useIdeaPageState } from "../IdeaPageState";

/**
 * 闪记编辑器半屏页。
 * 支持新建和编辑闪记，提供标题和内容的手动保存。
 */
@ComponentV2
export struct IdeaEditorContent {
  @Local private app: AppState = useAppState();
  @Local private state: IdeaPageState = useIdeaPageState();
  @Param hideInnerHeader: boolean = false;

  private repository: IdeaRepository = new IdeaRepository();

  @Local private title: string = "";
  @Local private content: string = "";
  @Local private isNew: boolean = true;
  @Local private currentIdea: Idea = new Idea();
  @Local private isSaving: boolean = false;

  aboutToAppear(): void {
    this.initializeDraft();
  }

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
  }

  private copyIdea(source: Idea): Idea {
    const idea = new Idea();
    idea.id = source.id;
    idea.title = source.title;
    idea.content = source.content;
    idea.length = source.length;
    idea.timestamp = source.timestamp;
    idea.createdAt = source.createdAt;
    idea.updatedAt = source.updatedAt;
    return idea;
  }

  private applyExistingIdea(idea: Idea): void {
    this.currentIdea = this.copyIdea(idea);
    this.title = this.currentIdea.title || "";
    this.content = this.currentIdea.content || "";
    this.isNew = false;
  }

  private applyNewIdeaDraft(): void {
    this.currentIdea = new Idea();
    this.title = "";
    this.content = "";
    this.isNew = true;
  }

  private initializeDraft(): void {
    const ideaId = this.normalizeId(this.state.editingIdeaId);
    if (ideaId <= 0) {
      this.applyNewIdeaDraft();
      return;
    }
    this.loadIdeaById(ideaId);
  }

  private async loadIdeaById(ideaId: number): Promise<void> {
    const localIdea = this.state.findIdeaInMemory(ideaId);
    if (localIdea !== null) {
      this.applyExistingIdea(localIdea);
      return;
    }
    try {
      const found = await this.repository.findById(ideaId);
      if (found !== null) {
        this.applyExistingIdea(found);
        return;
      }
      this.safeToast("未找到对应闪记");
      this.app.nav.back(false);
    } catch (_error) {
      this.safeToast("读取闪记失败");
      this.app.nav.back(false);
    }
  }

  private async resolveSavedIdea(): Promise<Idea> {
    const savedId = this.currentIdea.id;
    if (savedId <= 0) {
      return this.copyIdea(this.currentIdea);
    }
    try {
      const latest = await this.repository.findById(savedId);
      if (latest !== null) {
        return this.copyIdea(latest);
      }
    } catch (_error) {
    }
    return this.copyIdea(this.currentIdea);
  }

  /**
   * 保存到数据库。
   */
  private async saveToRepository(): Promise<void> {
    // 检查内容是否为空
    const trimmedContent = this.content.trim();
    if (trimmedContent.length === 0 && this.title.trim().length === 0) {
      return; // 空内容不保存
    }

    this.isSaving = true;
    const now = Date.now();
    this.currentIdea.title = this.title.trim();
    this.currentIdea.content = trimmedContent;
    this.currentIdea.length = trimmedContent.length;
    this.currentIdea.timestamp = now;

    if (this.isNew) {
      this.currentIdea.createdAt = now;
      this.currentIdea.updatedAt = now;
    } else {
      this.currentIdea.updatedAt = now;
    }

    try {
      await this.repository.save(this.currentIdea);
    } catch (_error) {
      this.safeToast("保存失败，请重试");
      this.isSaving = false;
      return;
    }

    const savedIdea = await this.resolveSavedIdea();
    await this.state.applySavedIdea(savedIdea);
    try {
      this.app.nav.back(false);
    } catch (_error) {
    }
    this.isSaving = false;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1200 });
    } catch (_error) {}
  }

  build() {
    Column({ space: 16 }) {
      if (!this.hideInnerHeader) {
        // 顶部标题栏
        Row() {
          Text(this.isNew ? "新建闪记" : "编辑闪记")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
          Blank()
          // 保存按钮
          Button(this.isSaving ? "保存中..." : "保存")
            .fontSize(14)
            .fontColor(this.app.theme.palette.surface)
            .backgroundColor(this.app.theme.palette.primary)
            .borderRadius(999)
            .height(40)
            .padding({ left: 16, right: 16 })
            .enabled(
              !this.isSaving && (this.content.trim().length > 0 || this.title.trim().length > 0),
            )
            .onClick(() => {
              this.saveToRepository();
            })
        }
        .width("100%")
        .margin({ bottom: 8 })
      } else {
        Row() {
          Blank()
          Button(this.isSaving ? "保存中..." : "保存")
            .fontSize(14)
            .fontColor(this.app.theme.palette.surface)
            .backgroundColor(this.app.theme.palette.primary)
            .borderRadius(999)
            .height(40)
            .padding({ left: 16, right: 16 })
            .enabled(
              !this.isSaving && (this.content.trim().length > 0 || this.title.trim().length > 0),
            )
            .onClick(() => {
              this.saveToRepository();
            })
        }
        .width("100%")
      }

      // 标题输入
      TextInput({ placeholder: "标题（可选）", text: this.title })
        .width("100%")
        .height(52)
        .fontSize(15)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.title = value;
        })

      // 内容输入
      TextArea({ placeholder: "写下你的闪念...", text: this.content })
        .width("100%")
        .layoutWeight(1)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(16)
        .textAlign(TextAlign.Start)
        .enterKeyType(EnterKeyType.NEW_LINE)
        .onChange((value: string) => {
          this.content = value;
        })
    }
    .width("100%")
    .height("100%");
  }
}
