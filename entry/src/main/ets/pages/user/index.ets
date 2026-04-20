import promptAction from '@ohos.promptAction';
import { FocusStatsChart } from "./components/FocusStatsChart";
import { SettingsPanel } from "./components/SettingsPanel";
import { UserActivityHeatmap } from './components/UserActivityHeatmap';
import { MainTabPageLayout } from "../../components/layout/MainTabPageLayout";
import { AppState, useAppState } from "../../app/AppStates";
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";
import { ThemeMode } from "../../core/theme/ThemeManager";
import { UserShareService } from '../../core/services/UserShareService';

/**
 * 组件功能简介：
 * - 我的页面主组件，负责用户资料展示、统计入口、设置入口与分享行为。
 *
 * 可传入项：
 * - `onBottomBarVisibleChange`：通知底部栏显示状态的回调。
 *
 * 返回行为：
 * - 渲染“我的”页面内容并响应主题切换、分享和登出交互。
 *
 * 副作用：
 * - 会触发主题设置更新、页面分享与退出登录操作。
 */
@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};
  private readonly SHARE_SNAPSHOT_ID: string = 'user_share_snapshot';
  private readonly userShareService: UserShareService = new UserShareService();

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
    await this.userShareService.shareSnapshot(
      this.getUIContext(),
      this.SHARE_SNAPSHOT_ID,
      (message: string): void => {
        this.safeToast(message);
      },
    );
  }

  @Builder
  private buildProfileCard(showThemeToggle: boolean) {
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
        if (showThemeToggle) {
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
  private buildStatsSection(showThemeToggle: boolean, snapshotId?: string) {
    Column({ space: 12 }) {
      this.buildProfileCard(showThemeToggle)
      FocusStatsChart()
      UserActivityHeatmap()
    }
    .width('100%')
    .id(snapshotId ?? '');
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
        Stack({ alignContent: Alignment.TopStart }) {
          Row() {
            Blank()
            Column({ space: 12 }) {
              this.buildStatsSection(true)
              SettingsPanel({
                onLogoutTap: async () => {
                  await this.handleLogout();
                },
              })
            }
            .width("100%")
            .constraintSize({ maxWidth: 760 })
            Blank()
          }
          .width("100%")

          Column() {
            this.buildStatsSection(false, this.SHARE_SNAPSHOT_ID)
          }
          .width("100%")
          .constraintSize({ maxWidth: 760 })
          .position({ x: -4000, y: 0 })
        }
        .width("100%")
      }
    };
  }
}
