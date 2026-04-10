import { Idea } from '../../../core/models/Idea';
import { IdeaRepository } from '../../../core/repositories/IdeaRepository';
import { ActionSheet, ActionSheetController } from '../../../components/card/ActionSheet';
import { AppState, useAppState } from '../../../app/AppStates';

/**
 * 闪记编辑器半屏页。
 * 支持新建和编辑闪记，提供标题和内容的自动保存。
 */
@ComponentV2
export struct IdeaEditorSheet {
  @Local private app: AppState = useAppState();
  @Param editIdea: Idea | null = null;
  @Event onSaved: (idea: Idea) => void = (_idea: Idea) => {};
  @Event onDismiss: () => void = () => {};

  private controller: ActionSheetController = new ActionSheetController();
  private repository: IdeaRepository = new IdeaRepository();
  private saveTimer: number = -1;

  @Local private title: string = '';
  @Local private content: string = '';
  @Local private isNew: boolean = true;
  @Local private currentIdea: Idea = new Idea();

  aboutToAppear(): void {
    if (this.editIdea) {
      this.currentIdea = this.editIdea;
      this.title = this.editIdea.title || '';
      this.content = this.editIdea.content || '';
      this.isNew = false;
    } else {
      this.currentIdea = new Idea();
      this.currentIdea.id = this.generateId();
      this.title = '';
      this.content = '';
      this.isNew = true;
    }
  }

  aboutToDisappear(): void {
    this.stopAutoSave();
  }

  /**
   * 生成唯一 ID。
   */
  private generateId(): string {
    return `idea_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * 防抖自动保存。
   */
  private scheduleAutoSave(): void {
    this.stopAutoSave();
    this.saveTimer = setTimeout(() => {
      this.saveToRepository();
    }, 800);
  }

  private stopAutoSave(): void {
    if (this.saveTimer >= 0) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
  }

  /**
   * 保存到数据库。
   */
  private saveToRepository(): void {
    const now = Date.now();
    this.currentIdea.title = this.title;
    this.currentIdea.content = this.content;
    this.currentIdea.length = this.content.length;
    this.currentIdea.timestamp = now;

    if (this.isNew) {
      this.currentIdea.createdAt = now;
      this.currentIdea.updatedAt = now;
    } else {
      this.currentIdea.updatedAt = now;
    }

    this.repository.save(this.currentIdea).then(() => {
      this.onSaved(this.currentIdea);
    });
  }

  /**
   * 处理标题输入变化。
   */
  private onTitleChange(value: string): void {
    this.title = value;
    this.scheduleAutoSave();
  }

  /**
   * 处理内容输入变化。
   */
  private onContentChange(value: string): void {
    this.content = value;
    this.scheduleAutoSave();
  }

  build() {
    ActionSheet({
      panelHeight: '70%',
      controller: this.controller,
      onDismiss: () => {
        this.stopAutoSave();
        this.onDismiss();
      }
    }) {
      Column({ space: 16 }) {
        // 顶部标题
        Row() {
          Text(this.isNew ? '新建闪记' : '编辑闪记')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary);
          Blank();
          Text('保存中...')
            .fontSize(12)
            .fontColor(this.app.theme.palette.textTertiary)
            .visibility(this.saveTimer >= 0 ? Visibility.Visible : Visibility.None);
        }
        .width('100%')
        .margin({ bottom: 8 });

        // 标题输入
        TextInput({ placeholder: '标题（可选）', text: this.title })
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontColor(this.app.theme.palette.textPrimary)
          .placeholderColor(this.app.theme.palette.textTertiary)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(12)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.onTitleChange(value);
          });

        // 内容输入
        TextArea({ placeholder: '写下你的闪念...', text: this.content })
          .width('100%')
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
            this.onContentChange(value);
          });
      }
      .width('100%')
      .height('100%');
    }
  }
}
