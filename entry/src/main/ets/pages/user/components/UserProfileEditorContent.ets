import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../../app/AppStates';
import { FormTypography } from '../../../core/theme/FormTypography';

@ComponentV2
export struct UserProfileEditorContent {
  @Local private app: AppState = useAppState();
  @Local private avatarDraft: string = '';
  @Local private passwordDraft: string = '';
  @Local private confirmPasswordDraft: string = '';
  @Local private saving: boolean = false;

  aboutToAppear(): void {
    this.avatarDraft = this.app.currentUserAvatar;
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

  private async submit(): Promise<void> {
    const password: string = this.normalizeText(this.passwordDraft);
    const confirmPassword: string = this.normalizeText(this.confirmPasswordDraft);
    if (password.length > 0 && password !== confirmPassword) {
      this.safeToast('两次输入的新密码不一致');
      return;
    }

    this.saving = true;
    try {
      const result = await this.app.updateCurrentUserProfile(this.normalizeText(this.avatarDraft), password);
      this.safeToast(result.message);
      if (result.success) {
        this.app.nav.back(false);
      }
    } finally {
      this.saving = false;
    }
  }

  build() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text('编辑资料')
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Button('保存')
          .height(34)
          .fontSize(12)
          .enabled(!this.saving)
          .fontColor(this.app.theme.palette.surface)
          .backgroundColor(this.app.theme.palette.primary)
          .borderRadius(999)
          .onClick(async () => {
            await this.submit();
          })
      }
      .width('100%')

      TextInput({ text: this.avatarDraft, placeholder: '头像字符，例如 A / 知 / 🙂' })
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.avatarDraft = value;
        })

      TextInput({ text: this.passwordDraft, placeholder: '新密码（留空则保持不变）' })
        .type(InputType.Password)
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.passwordDraft = value;
        })

      TextInput({ text: this.confirmPasswordDraft, placeholder: '再次输入新密码' })
        .type(InputType.Password)
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.confirmPasswordDraft = value;
        })

      Text('当前版本先支持头像字符与密码更新，登录账号本身保持不变，以避免影响按用户分库的数据目录。')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(this.app.theme.palette.textSecondary)
        .width('100%')
    }
    .width('100%');
  }
}
