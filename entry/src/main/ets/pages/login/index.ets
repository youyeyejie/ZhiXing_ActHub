import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 登录/注册页面组件，负责账号密码输入、模式切换与认证提交。
 *
 * 可传入项：
 * - 无（通过 `AppState` 调用全局认证能力）。
 *
 * 返回行为：
 * - 渲染认证表单并在提交后反馈认证结果。
 *
 * 副作用：
 * - 会触发登录/注册请求并弹出 Toast 提示。
 */
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

  private isModeActive(registerMode: boolean): boolean {
    return this.isRegisterMode === registerMode;
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
  private buildModeButton(label: string, registerMode: boolean) {
    Button() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.isModeActive(registerMode) ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.isModeActive(registerMode) ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary);
    }
      .layoutWeight(1)
      .height(40)
      .stateEffect(false)
      .backgroundColor(this.isModeActive(registerMode) ? this.app.theme.palette.primary : Color.Transparent)
      .borderRadius(12)
      .onClick(() => {
        this.switchMode(registerMode);
      });
  }

  build() {
    Scroll() {
      Column({ space: 24 }) {
        Column({ space: 12 }) {
          Column() {
            Image($r('app.media.foreground'))
              .width(96)
              .height(96)
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
            this.buildModeButton('登录', false);
            this.buildModeButton('注册', true);
          }
          .width('100%')
          .padding(4)
          .borderRadius(16)
          .backgroundColor(this.app.theme.palette.surfaceSecondary);

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
