import { Idea } from "../../../core/models/Idea";
import { IdeaRepository } from "../../../core/repositories/IdeaRepository";
import { ActionSheet, ActionSheetController } from "../../../components/card/ActionSheet";
import { AppState, useAppState } from "../../../app/AppStates";

/**
 * 闪记编辑器半屏页。
 * 支持新建和编辑闪记，提供标题和内容的手动保存。
 */
@ComponentV2
export struct IdeaEditorSheet {
  @Local private app: AppState = useAppState();
  @Param editIdea: Idea | null = null;
  @Event onSaved: (idea: Idea) => void = (_idea: Idea) => {};
  @Event onDismiss: () => void = () => {};

  private controller: ActionSheetController = new ActionSheetController();
  private repository: IdeaRepository = new IdeaRepository();

  @Local private title: string = "";
  @Local private content: string = "";
  @Local private isNew: boolean = true;
  @Local private currentIdea: Idea = new Idea();
  @Local private isSaving: boolean = false;

  aboutToAppear(): void {
    if (this.editIdea) {
      this.currentIdea = this.editIdea;
      this.title = this.editIdea.title || "";
      this.content = this.editIdea.content || "";
      this.isNew = false;
    } else {
      this.currentIdea = new Idea();
      this.currentIdea.id = this.generateId();
      this.title = "";
      this.content = "";
      this.isNew = true;
    }
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
      this.onSaved(this.currentIdea);
    } catch (_error) {
      // 忽略错误
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    ActionSheet({
      panelHeight: "70%",
      controller: this.controller,
      onDismiss: () => {
        this.onDismiss();
      },
    }) {
      Column({ space: 16 }) {
        // 顶部标题栏
        Row() {
          Text(this.isNew ? "新建闪记" : "编辑闪记")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
          Blank()
          // 保存按钮
          Button(this.isSaving ? "保存中..." : "保存")
            .fontSize(14)
            .fontColor("#FFFFFF")
            .backgroundColor(this.app.theme.palette.primary)
            .borderRadius(8)
            .height(32)
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

        // 标题输入
        TextInput({ placeholder: "标题（可选）", text: this.title })
          .width("100%")
          .height(44)
          .fontSize(16)
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
          .fontSize(16)
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
      .height("100%")
    };
  }
}
