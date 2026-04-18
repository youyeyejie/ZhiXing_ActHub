import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';
import { FocusStatsChart } from "./components/FocusStatsChart";
import { SettingsPanel } from "./components/SettingsPanel";
import { UserActivityHeatmap } from './components/UserActivityHeatmap';
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { AppState, useAppState } from "../../app/AppStates";
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";
import { ThemeMode } from "../../core/theme/ThemeManager";

@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};
  private readonly SHARE_SNAPSHOT_ID: string = 'user_share_snapshot';

  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
  }

  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  private resolveDisplayName(): string {
    const name: string = `${this.app.currentUserName}`.trim();
    return name.length > 0 ? name : "未登录用户";
  }

  private resolveInitial(): string {
    return this.resolveDisplayName().substring(0, 1).toUpperCase();
  }

  private resolveJoinedText(): string {
    const user = this.app.currentUser;
    if (user === null || user.createdAt <= 0) {
      return "本地账号";
    }
    return "加入于 " + this.formatDate(user.createdAt);
  }

  private formatDate(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = String(date.getMonth() + 1).padStart(2, "0");
    const day: string = String(date.getDate()).padStart(2, "0");
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private resolveThemeModeIcon(): Resource {
    const mode: ThemeMode = this.app.theme.get();
    if (mode === ThemeMode.DARK) {
      return $r('sys.symbol.dark_mode');
    }
    if (mode === ThemeMode.SYSTEM) {
      return $r('sys.symbol.auto_mode');
    }
    return $r('sys.symbol.light_mode');
  }

  private async cycleThemeMode(): Promise<void> {
    const mode: ThemeMode = this.app.theme.get();
    let nextMode: ThemeMode = ThemeMode.LIGHT;
    if (mode === ThemeMode.LIGHT) {
      nextMode = ThemeMode.DARK;
    } else if (mode === ThemeMode.DARK) {
      nextMode = ThemeMode.SYSTEM;
    }
    await this.app.setPreferredThemeMode(nextMode);
  }

  private async handleLogout(): Promise<void> {
    await this.app.logout();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1400 });
    } catch (_error) {
    }
  }

  private async handleShare(): Promise<void> {
    try {
      const snapshot = await this.getUIContext().getComponentSnapshot().get(this.SHARE_SNAPSHOT_ID, {
        scale: 2,
        waitUntilRenderFinished: true,
      });
      const board = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.MIMETYPE_PIXELMAP, snapshot);
      await board.setData(data);
      this.safeToast('分享图已复制到剪贴板，可直接粘贴发送');
    } catch (_error) {
      this.safeToast('生成分享图失败，请稍后重试');
    }
  }

  @Builder
  private buildInfoChip(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(this.app.theme.palette.textTertiary)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
    }
    .layoutWeight(1)
    .padding(14)
    .borderRadius(16)
    .backgroundColor(this.app.theme.palette.surfaceSecondary);
  }

  @Builder
  private buildProfileCard() {
    Column({ space: 16 }) {
      Row({ space: 14 }) {
        Text(this.resolveInitial())
          .width(58)
          .height(58)
          .borderRadius(29)
          .backgroundColor(this.app.theme.palette.primary)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.surface)
          .textAlign(TextAlign.Center)
        Column({ space: 4 }) {
          Text(this.resolveDisplayName())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary)
          Text(this.resolveJoinedText())
            .fontSize(13)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.resolveThemeModeIcon())
            .fontSize(28)
            .fontColor([this.app.theme.palette.textSecondary])
        }
        .width(42)
        .height(42)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .onClick(async () => {
          await this.cycleThemeMode();
        })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .padding(18)
    .borderRadius(24)
    .backgroundColor(this.app.theme.palette.surface);
  }

  @Builder
  private buildShareableStatsSection() {
    Column({ space: 12 }) {
      this.buildProfileCard()
      FocusStatsChart()
      UserActivityHeatmap()
    }
    .width('100%')
    .id(this.SHARE_SNAPSHOT_ID);
  }

  build() {
    MainTabPageLayout({
      title: "我的",
      actionIcon: $r('sys.symbol.share'),
      onActionTap: async () => {
        await this.handleShare();
      },
    }) {
      PageScrollLayout({ space: 12, paddingTop: 0 }) {
        Row() {
          Blank()
          Column({ space: 12 }) {
            this.buildShareableStatsSection()
            SettingsPanel({
              onLogoutTap: async () => {
                await this.handleLogout();
              },
            })
          }
          .width("100%")
          .constraintSize({ maxWidth: 760 })
          Blank()
        }.width("100%")
      }
    };
  }
}
