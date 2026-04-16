import promptAction from "@ohos.promptAction";
import { common } from "@kit.AbilityKit";
import { AppState, useAppState } from "../../../app/AppStates";
import { AppPreferenceKey } from "../../../app/AppConstants";
import { CalendarReminderService } from "../../../core/services/CalendarReminderService";
import { NotificationService } from "../../../core/services/NotificationService";
import { UserPreferenceRepository } from "../../../core/repositories/UserPreferenceRepository";
import {
  ImportExportResult,
  ImportExportService,
} from "../../../core/services/ImportExportService";
@ComponentV2
export struct SettingsPanel {
  @Local private app: AppState = useAppState();
  @Local private notificationEnabled: boolean = true;
  @Local private reminderEnabled: boolean = false;
  @Local private importExportRunning: boolean = false;
  @Local private importExportExpanded: boolean = false;
  @Event onLogoutTap: () => void = () => {};

  private userPreferenceRepository: UserPreferenceRepository = new UserPreferenceRepository();
  private calendarReminderService: CalendarReminderService = new CalendarReminderService();
  private importExportService: ImportExportService = new ImportExportService();

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
    if (enabled) {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const granted = await this.calendarReminderService.requestCalendarPermission(context);
      if (!granted) {
        this.reminderEnabled = false;
        await this.userPreferenceRepository.setBoolean(AppPreferenceKey.PLAN_REMINDER_ENABLED, false);
        this.safeToast("日历权限未开启，请在系统设置里设置");
        return;
      }

      this.reminderEnabled = true;
      await this.userPreferenceRepository.setBoolean(AppPreferenceKey.PLAN_REMINDER_ENABLED, true);
      await this.calendarReminderService.registerPlanReminder();
      this.safeToast("日程提醒已开启");
      return;
    }

    this.reminderEnabled = false;
    await this.userPreferenceRepository.setBoolean(AppPreferenceKey.PLAN_REMINDER_ENABLED, false);
    await this.calendarReminderService.cancelPlanReminder();
    this.safeToast("日程提醒已关闭");
  }

  private async handleNotificationToggle(enabled: boolean): Promise<boolean> {
    if (!enabled) {
      this.notificationEnabled = false;
      await this.userPreferenceRepository.setBoolean(AppPreferenceKey.NOTIFICATION_ENABLED, false);
      NotificationService.cancelFocusNotification();
      this.safeToast("专注通知已关闭");
      return true;
    }

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const granted = await NotificationService.requestNotificationPermission(context);
    if (!granted) {
      this.notificationEnabled = false;
      await this.userPreferenceRepository.setBoolean(AppPreferenceKey.NOTIFICATION_ENABLED, false);
      this.safeToast("通知权限未开启，请在系统设置里设置");
      return false;
    }

    this.notificationEnabled = true;
    await this.userPreferenceRepository.setBoolean(AppPreferenceKey.NOTIFICATION_ENABLED, true);
    this.safeToast("专注通知已开启");
    return true;
  }

  private async runImportExportAction(index: number): Promise<void> {
    if (this.importExportRunning) {
      return;
    }

    this.importExportRunning = true;
    try {
      let result: ImportExportResult;
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (index === 0) {
        result = await this.importExportService.importUserData(context, this.app);
      } else if (index === 1) {
        result = await this.importExportService.exportUserData(context, this.app);
      } else if (index === 2) {
        result = await this.importExportService.importCourseIcs(context, this.app);
      } else {
        result = await this.importExportService.exportCourseIcs(context, this.app);
      }
      await this.syncReminderStateAfterImportExport(index, result);
      this.safeToast(result.message);
    } catch (_error) {
      this.safeToast("操作失败，请稍后重试");
    } finally {
      this.importExportRunning = false;
    }
  }

  private async syncReminderStateAfterImportExport(
    index: number,
    result: ImportExportResult,
  ): Promise<void> {
    if (!result.success) {
      return;
    }

    if (index === 2) {
      await this.app.syncCalendarRemindersForCurrentUser();
    }
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

  @Builder
  private buildImportExportInlineButton(label: string, index: number) {
    Button(label)
      .height(30)
      .fontSize(12)
      .fontColor(this.app.theme.palette.textPrimary)
      .backgroundColor(this.app.theme.palette.surface)
      .borderRadius(999)
      .enabled(!this.importExportRunning)
      .onClick(async () => {
        await this.runImportExportAction(index);
      });
  }

  @Builder
  private buildImportExportItemRow(title: string, importIndex: number, exportIndex: number) {
    Row({ space: 10 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(this.app.theme.palette.textPrimary)
        .layoutWeight(1)

      this.buildImportExportInlineButton("导入", importIndex)
      this.buildImportExportInlineButton("导出", exportIndex)
    }
    .width("100%")
    .height(40)
    .padding({ left: 6, right: 6 });
  }

  @Builder
  private buildImportExportMenuRow() {
    Column({ space: 0 }) {
      Button() {
        Row({ space: 12 }) {
          Text("导入导出")
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
            .layoutWeight(1)
          SymbolGlyph(
            this.importExportExpanded
              ? $r("sys.symbol.chevron_down")
              : $r("sys.symbol.chevron_right"),
          )
            .fontSize(16)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([this.app.theme.palette.textSecondary])
        }.width("100%")
      }
      .width("100%")
      .padding(16)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)
      .onClick(() => {
        this.importExportExpanded = !this.importExportExpanded;
      })

      if (this.importExportExpanded) {
        Column({ space: 0 }) {
          Divider()
            .strokeWidth(1)
            .color(this.app.theme.palette.border)
          Column({ space: 0 }) {
            this.buildImportExportItemRow("用户数据", 0, 1)
            Divider()
              .strokeWidth(1)
              .color(this.app.theme.palette.border)
            this.buildImportExportItemRow("课程数据", 2, 3)
          }
          .width("100%")
          .padding({ left: 12, right: 12, top: 2, bottom: 2 })
        };
      }
    }
    .width("100%")
    .borderRadius(18)
    .clip(true)
    .backgroundColor(this.app.theme.palette.surfaceSecondary);
  }

  build() {
    Column({ space: 12 }) {
      Text("设置选项")
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
      Row({ space: 12 }) {
        Text("专注通知")
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
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
        Text("日历提醒")
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.reminderEnabled })
          .onChange(async (value: boolean) => {
            await this.handleReminderToggle(value);
          })
      }
      .width("100%")
      .padding(16)
      .borderRadius(18)
      .backgroundColor(this.app.theme.palette.surfaceSecondary)

      this.buildImportExportMenuRow()
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
