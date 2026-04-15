import promptAction from "@ohos.promptAction";
import { common } from "@kit.AbilityKit";
import { AppState, useAppState } from "../../../app/AppStates";
import { AppPreferenceKey } from "../../../app/AppConstants";
import { NotificationService } from "../../../core/services/NotificationService";
import { UserPreferenceRepository } from "../../../core/repositories/UserPreferenceRepository";
@ComponentV2
export struct SettingsPanel {
  @Local private app: AppState = useAppState();
  @Local private notificationEnabled: boolean = true;
  @Local private reminderEnabled: boolean = false;
  @Event onLogoutTap: () => void = () => {};

  private userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();
  private notificationService: NotificationService = new NotificationService();

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    this.notificationEnabled = await this.userPreferenceRepository.getBoolean(
      AppPreferenceKey.NOTIFICATION_ENABLED,
      true,
    );
    this.reminderEnabled = await this.userPreferenceRepository.getBoolean(
      AppPreferenceKey.PLAN_REMINDER_ENABLED,
      false,
    );
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1400 });
    } catch (_error) {}
  }

  private async handleReminderToggle(enabled: boolean): Promise<void> {
    this.reminderEnabled = enabled;
    await this.userPreferenceRepository.setBoolean(AppPreferenceKey.PLAN_REMINDER_ENABLED, enabled);
    if (enabled) {
      await this.notificationService.registerPlanReminder();
      this.safeToast("日程提醒已开启");
      return;
    }
    await this.notificationService.cancelPlanReminder();
    this.safeToast("日程提醒已关闭");
  }

  private async handleNotificationToggle(enabled: boolean): Promise<boolean> {
    if (!enabled) {
      this.notificationEnabled = false;
      await this.userPreferenceRepository.setBoolean(AppPreferenceKey.NOTIFICATION_ENABLED, false);
      NotificationService.cancelFocusNotification();
      this.safeToast("系统通知已关闭");
      return true;
    }

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const granted = await NotificationService.requestNotificationPermission(context);
    if (granted) {
      this.notificationEnabled = true;
      await this.userPreferenceRepository.setBoolean(AppPreferenceKey.NOTIFICATION_ENABLED, true);
      this.safeToast("系统通知已开启");
      return true;
    }
    this.notificationEnabled = false;
    await this.userPreferenceRepository.setBoolean(AppPreferenceKey.NOTIFICATION_ENABLED, false);
    this.safeToast("通知权限未开启，请在系统设置里设置");
    return false;
  }

  @Builder
  private buildActionRow(title: string, subtitle: string, buttonLabel: string, onTap: () => void) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
        Text(subtitle)
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.app.theme.palette.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Button(buttonLabel)
        .height(34)
        .fontSize(12)
        .fontColor(this.app.theme.palette.textPrimary)
        .backgroundColor(this.app.theme.palette.surface)
        .borderRadius(999)
        .onClick(() => {
          onTap();
        })
    }
    .width("100%")
    .padding(16)
    .borderRadius(18)
    .backgroundColor(this.app.theme.palette.surfaceSecondary);
  }

  build() {
    Column({ space: 12 }) {
      Text("设置选项")
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text("系统通知")
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
          Text("用户级通知总开关。关闭后 NotificationService 会直接跳过系统通知发送。")
            .fontSize(12)
            .lineHeight(18)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Toggle({ type: ToggleType.Switch, isOn: $$this.notificationEnabled })
          .onChange(async (value: boolean) => {
            const success = await this.handleNotificationToggle(value);
            if (!success) {
              this.notificationEnabled = false;
            }
          })
      }
      .width("100%")
      .padding(16)
      .borderRadius(18)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text("日程提醒通知")
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
          Text("预留提醒总开关；系统通知总开关关闭时，相关通知调用会被直接跳过。")
            .fontSize(12)
            .lineHeight(18)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Toggle({ type: ToggleType.Switch, isOn: this.reminderEnabled })
          .onChange(async (value: boolean) => {
            await this.handleReminderToggle(value);
          })
      }
      .width("100%")
      .padding(16)
      .borderRadius(18)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)

      this.buildActionRow(
        "导入日程",
        "预留 ICS / CSV 文件导入入口，后续只需接文件选择器和解析逻辑。",
        "预留",
        () => {
          this.safeToast("导入日程入口已预留");
        },
      )

      this.buildActionRow(
        "导出本地数据",
        "预留本地数据导出能力，后续可选择导出待办、日程、闪记等内容。",
        "预留",
        () => {
          this.safeToast("导出本地数据入口已预留");
        },
      )

      this.buildActionRow(
        "同步空间",
        "云同步是扩展功能，本期先保留设置位置，方便后续直接接入。",
        "预留",
        () => {
          this.safeToast("同步能力为扩展预留项");
        },
      )
      Button("退出登录")
        .width("100%")
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.surface)
        .backgroundColor(this.app.theme.palette.primary)
        .borderRadius(16)
        .onClick(() => {
          this.onLogoutTap();
        })
    }
    .width("100%")
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
