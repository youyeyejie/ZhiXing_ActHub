import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../../app/AppStates';
import { FormTypography } from '../../../core/theme/FormTypography';

@ComponentV2
export struct PasswordEditorContent {
  @Local private app: AppState = useAppState();
  @Local private oldPassword: string = '';
  @Local private newPassword: string = '';
  @Local private confirmPassword: string = '';
  @Local private saving: boolean = false;

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
    const oldPassword: string = this.normalizeText(this.oldPassword);
    const newPassword: string = this.normalizeText(this.newPassword);
    const confirmPassword: string = this.normalizeText(this.confirmPassword);
    if (oldPassword.length === 0) {
      this.safeToast('请输入旧密码');
      return;
    }
    if (newPassword.length < 6) {
      this.safeToast('新密码至少需要 6 位');
      return;
    }
    if (newPassword !== confirmPassword) {
      this.safeToast('两次输入的新密码不一致');
      return;
    }

    this.saving = true;
    try {
      const result = await this.app.changeCurrentUserPassword(oldPassword, newPassword);
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
        Text('修改密码')
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

      TextInput({ text: this.oldPassword, placeholder: '旧密码' })
        .type(InputType.Password)
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.oldPassword = value;
        })

      TextInput({ text: this.newPassword, placeholder: '新密码' })
        .type(InputType.Password)
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.newPassword = value;
        })

      TextInput({ text: this.confirmPassword, placeholder: '再次输入新密码' })
        .type(InputType.Password)
        .width('100%')
        .height(56)
        .fontSize(FormTypography.INPUT_CONTENT_SIZE)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string) => {
          this.confirmPassword = value;
        })
    }
    .width('100%');
  }
}
