import { Idea } from "../../../core/models/Idea";
import { IdeaRepository } from "../../../core/repositories/IdeaRepository";
import { AppState, useAppState } from "../../../app/AppStates";
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
  @Local private saveEnabled: boolean = false;

  aboutToAppear(): void {
    this.initializeDraft();
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
    this.recalculateSaveEnabled();
  }

  private applyNewIdeaDraft(): void {
    this.currentIdea = new Idea();
    this.currentIdea.id = this.generateId();
    this.title = "";
    this.content = "";
    this.isNew = true;
    this.recalculateSaveEnabled();
  }

  private initializeDraft(): void {
    const ideaId = this.normalizeId(this.state.editingIdeaId);
    if (ideaId.length === 0) {
      this.applyNewIdeaDraft();
      return;
    }
    this.loadIdeaById(ideaId);
  }

  private async loadIdeaById(ideaId: string): Promise<void> {
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
      this.app.nav.back(false);
    } catch (_error) {
      this.app.nav.back(false);
    }
  }

  private async resolveSavedIdea(): Promise<Idea> {
    const savedId = this.normalizeId(this.currentIdea.id);
    if (savedId.length === 0) {
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
   * 生成唯一 ID。
   */
  private generateId(): string {
    return `idea_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * 保存到数据库。
   */
  private async saveToRepository(): Promise<void> {
    if (!this.computeCanSave()) {
      this.recalculateSaveEnabled();
      return;
    }

    this.isSaving = true;
    this.recalculateSaveEnabled();
    const trimmedContent = this.normalizeText(this.content);
    const now = Date.now();
    this.currentIdea.title = this.normalizeText(this.title);
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
      this.isSaving = false;
      this.recalculateSaveEnabled();
      return;
    }

    const savedIdea = await this.resolveSavedIdea();
    await this.state.applySavedIdea(savedIdea);
    try {
      this.app.nav.back(false);
    } catch (_error) {
    }
    this.isSaving = false;
    this.recalculateSaveEnabled();
  }

  private recalculateSaveEnabled(): void {
    this.saveEnabled = this.computeCanSave();
  }

  private hasRequiredFieldsFilled(): boolean {
    return this.normalizeText(this.content).length > 0;
  }

  private computeCanSave(): boolean {
    return !this.isSaving && this.hasRequiredFieldsFilled();
  }

  private canDelete(): boolean {
    if (this.isSaving || !this.hideInnerHeader || this.isNew) {
      return false;
    }
    return this.normalizeId(this.currentIdea.id).length > 0;
  }

  private deleteCurrentIdea(): void {
    if (!this.canDelete()) {
      return;
    }
    const ideaId = this.normalizeId(this.currentIdea.id);
    const inMemory = this.state.findIdeaInMemory(ideaId);
    const target = inMemory === null ? this.copyIdea(this.currentIdea) : inMemory;
    this.state.requestDeleteIdea(target);
    this.app.nav.back(false);
  }

  private resolveHeaderActionButtonBackground(enabled: boolean, danger: boolean): string {
    if (danger) {
      return this.app.theme.palette.dangerSurface;
    }
    if (enabled) {
      return this.app.theme.palette.primary;
    }
    return this.app.theme.palette.surfaceSecondary;
  }

  private resolveHeaderActionButtonForeground(enabled: boolean, danger: boolean): string {
    if (danger) {
      return this.app.theme.palette.danger;
    }
    if (enabled) {
      return this.app.theme.palette.surface;
    }
    return this.app.theme.palette.textTertiary;
  }

  @Builder
  private buildHeaderActionButton(icon: Resource, enabled: boolean, danger: boolean, onTap: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: enabled }) {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor([this.resolveHeaderActionButtonForeground(enabled, danger)]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.resolveHeaderActionButtonBackground(enabled, danger))
      .opacity(enabled ? 1 : 0.56)
      .onClick(() => {
        if (!enabled) {
          return;
        }
        onTap();
      });
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 10 }) {
        Text(this.isNew ? "新建闪记" : "编辑闪记")
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)

        if (this.saveEnabled) {
          this.buildHeaderActionButton($r("sys.symbol.save"), true, false, () => {
            this.saveToRepository();
          });
        } else {
          this.buildHeaderActionButton($r("sys.symbol.save"), false, false, () => {
            this.saveToRepository();
          });
        }

        if (this.hideInnerHeader) {
          this.buildHeaderActionButton($r("sys.symbol.trash"), this.canDelete(), true, () => {
            this.deleteCurrentIdea();
          });
        }
      }
      .width("100%")

      TextInput({ placeholder: "标题（可选）", text: this.title })
        .width("100%")
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.title = value;
          this.recalculateSaveEnabled();
        })

      TextArea({ placeholder: "写下你的闪念（必填）...", text: this.content })
        .width("100%")
        .layoutWeight(1)
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary)
        .placeholderColor(this.app.theme.palette.textTertiary)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(16)
        .textAlign(TextAlign.Start)
        .enterKeyType(EnterKeyType.NEW_LINE)
        .onChange((value: string) => {
          this.content = value;
          this.recalculateSaveEnabled();
        })
    }
    .width("100%")
    .height("100%");
  }
}
