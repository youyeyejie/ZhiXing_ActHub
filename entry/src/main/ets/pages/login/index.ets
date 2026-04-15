import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../app/AppStates';

@ComponentV2
export struct LoginPage {
  @Local private app: AppState = useAppState();
  @Local private isRegisterMode: boolean = false;
  @Local private account: string = '';
  @Local private password: string = '';
  @Local private confirmPassword: string = '';
  @Local private submitting: boolean = false;

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1400 });
    } catch (_error) {
    }
  }

  private validateDraft(): string {
    const account: string = `${this.account}`.trim();
    const password: string = `${this.password}`.trim();
    if (account.length < 2) {
      return '账号至少需要 2 个字符';
    }
    if (password.length < 6) {
      return '密码至少需要 6 个字符';
    }
    if (this.isRegisterMode && password !== `${this.confirmPassword}`.trim()) {
      return '两次输入的密码不一致';
    }
    return '';
  }

  private switchMode(isRegisterMode: boolean): void {
    this.isRegisterMode = isRegisterMode;
    this.password = '';
    this.confirmPassword = '';
  }

  private async submit(): Promise<void> {
    if (this.submitting) {
      return;
    }

    const validationMessage: string = this.validateDraft();
    if (validationMessage.length > 0) {
      this.safeToast(validationMessage);
      return;
    }

    this.submitting = true;
    const account: string = `${this.account}`.trim();
    const password: string = `${this.password}`.trim();
    const result = this.isRegisterMode
      ? await this.app.register(account, password)
      : await this.app.login(account, password);
    this.submitting = false;

    if (!result.success) {
      this.safeToast(result.message);
      return;
    }

    this.confirmPassword = '';
    this.safeToast(result.message);
  }

  @Builder
  private buildModeButton(label: string, active: boolean, onTap: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .backgroundColor(active ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .fontColor(active ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .fontSize(14)
      .fontWeight(active ? FontWeight.Medium : FontWeight.Regular)
      .borderRadius(14)
      .onClick(() => {
        onTap();
      });
  }

  build() {
    Scroll() {
      Column({ space: 24 }) {
        Column({ space: 12 }) {
          Column() {
            Image($r('app.media.foreground'))
              .width(72)
              .height(72)
              .objectFit(ImageFit.Contain);
          }
          .width(108)
          .height(108)
          .borderRadius(28)
          .backgroundColor(this.app.theme.palette.surface)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Text('知行')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary);

          Text('登录后继续你的计划、待办、专注与闪记')
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary)
            .textAlign(TextAlign.Center);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        Column({ space: 16 }) {
          Row({ space: 8 }) {
            this.buildModeButton('登录', !this.isRegisterMode, () => {
              this.switchMode(false);
            });
            this.buildModeButton('注册', this.isRegisterMode, () => {
              this.switchMode(true);
            });
          }
          .width('100%');

          TextInput({ text: this.account, placeholder: '请输入账号' })
            .width('100%')
            .height(52)
            .fontSize(15)
            .fontColor(this.app.theme.palette.textPrimary)
            .placeholderColor(this.app.theme.palette.textTertiary)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .borderRadius(14)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.account = value;
            });

          TextInput({ text: this.password, placeholder: '请输入密码' })
            .type(InputType.Password)
            .width('100%')
            .height(52)
            .fontSize(15)
            .fontColor(this.app.theme.palette.textPrimary)
            .placeholderColor(this.app.theme.palette.textTertiary)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .borderRadius(14)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.password = value;
            });

          if (this.isRegisterMode) {
            TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
              .type(InputType.Password)
              .width('100%')
              .height(52)
              .fontSize(15)
              .fontColor(this.app.theme.palette.textPrimary)
              .placeholderColor(this.app.theme.palette.textTertiary)
              .backgroundColor(this.app.theme.palette.surfaceSecondary)
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.confirmPassword = value;
              });
          }

          Button(this.submitting ? (this.isRegisterMode ? '注册中...' : '登录中...') : (this.isRegisterMode ? '注册并进入' : '登录进入'))
            .width('100%')
            .height(48)
            .backgroundColor(this.app.theme.palette.primary)
            .fontColor(this.app.theme.palette.surface)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .borderRadius(16)
            .enabled(!this.submitting)
            .onClick(async () => {
              await this.submit();
            });

          Text(this.isRegisterMode
            ? '注册成功后会自动登录，下次启动会直接跳过登录页。'
            : '支持登录状态保持，已登录用户会直接进入主界面。')
            .fontSize(12)
            .fontColor(this.app.theme.palette.textTertiary)
            .lineHeight(18);
        }
        .width('100%')
        .padding(20)
        .borderRadius(24)
        .backgroundColor(this.app.theme.palette.surface);
      }
      .width('100%')
      .constraintSize({ maxWidth: 520 })
      .padding({ left: 24, right: 24, top: 52, bottom: 52 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
