import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../../app/AppStates';
import { AIConfigSnapshot, AIService, useAIService } from '../../../core/services/AIService';
import { FormTypography } from '../../../core/theme/FormTypography';

@ComponentV2
export struct AIConfigEditorContent {
  @Local private app: AppState = useAppState();
  @Local private aiService: AIService = useAIService();
  @Local private apiKeyDraft: string = '';
  @Local private baseUrlDraft: string = '';
  @Local private modelDraft: string = '';
  @Local private saving: boolean = false;
  @Local private testing: boolean = false;

  aboutToAppear(): void {
    this.loadDraft();
  }

  private async loadDraft(): Promise<void> {
    await this.aiService.loadPersistedOverrides();
    const snapshot: AIConfigSnapshot = this.aiService.getConfigSnapshot();
    this.apiKeyDraft = snapshot.apiKey;
    this.baseUrlDraft = snapshot.baseUrl;
    this.modelDraft = snapshot.model;
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1600 });
    } catch (_error) {}
  }

  private async saveConfig(): Promise<void> {
    this.saving = true;
    try {
      await this.aiService.saveConfig(
        new AIConfigSnapshot(
          this.normalizeText(this.apiKeyDraft),
          this.normalizeText(this.baseUrlDraft),
          this.normalizeText(this.modelDraft),
        ),
      );
      this.safeToast('AI 配置已保存');
      this.app.nav.back(false);
    } finally {
      this.saving = false;
    }
  }

  private async testConnection(): Promise<void> {
    this.testing = true;
    try {
      await this.aiService.saveConfig(
        new AIConfigSnapshot(
          this.normalizeText(this.apiKeyDraft),
          this.normalizeText(this.baseUrlDraft),
          this.normalizeText(this.modelDraft),
        ),
      );
      const message: string = await this.aiService.testConnection();
      this.safeToast(message);
    } finally {
      this.testing = false;
    }
  }

  build() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text('AI 洞察配置')
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Button(this.testing ? '测试中' : '测试连接')
          .height(34)
          .fontSize(12)
          .enabled(!this.testing && !this.saving)
          .fontColor(this.app.theme.palette.textPrimary)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(999)
          .onClick(async () => {
            await this.testConnection();
          })
        Button('保存')
          .height(34)
          .fontSize(12)
          .enabled(!this.saving)
          .fontColor(this.app.theme.palette.surface)
          .backgroundColor(this.app.theme.palette.primary)
          .borderRadius(999)
          .onClick(async () => {
            await this.saveConfig();
          })
      }
      .width('100%')

      TextInput({ text: this.baseUrlDraft, placeholder: 'Base URL' })
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.baseUrlDraft = value;
        })

      TextInput({ text: this.apiKeyDraft, placeholder: 'API Key' })
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.apiKeyDraft = value;
        })

      TextInput({ text: this.modelDraft, placeholder: 'Model' })
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.modelDraft = value;
        })
    }
    .width('100%');
  }
}
