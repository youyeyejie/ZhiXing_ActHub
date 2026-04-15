import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppState, useAppState } from '../../app/AppStates';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';
import { ThemeMode } from '../../core/theme/ThemeManager';

@ComponentV2
export struct UserPage {
  @Local private app: AppState = useAppState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
  }

  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  private resolveDisplayName(): string {
    const name: string = `${this.app.currentUserName}`.trim();
    return name.length > 0 ? name : '未登录用户';
  }

  private resolveInitial(): string {
    return this.resolveDisplayName().substring(0, 1).toUpperCase();
  }

  private resolveJoinedText(): string {
    const user = this.app.currentUser;
    if (user === null || user.createdAt <= 0) {
      return '本地账号 | 登录状态已保持';
    }
    return '加入于 ' + this.formatDate(user.createdAt) + ' | 本地账号';
  }

  private formatDate(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private async setThemeBySwitch(isDarkMode: boolean): Promise<void> {
    await this.app.setPreferredThemeMode(isDarkMode ? ThemeMode.DARK : ThemeMode.LIGHT);
  }

  private async handleLogout(): Promise<void> {
    await this.app.logout();
  }

  @Builder
  private buildInfoChip(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(this.app.theme.palette.textTertiary);
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);
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
          .textAlign(TextAlign.Center);

        Column({ space: 4 }) {
          Text(this.resolveDisplayName())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary);

          Text(this.resolveJoinedText())
            .fontSize(13)
            .fontColor(this.app.theme.palette.textSecondary);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Column({ space: 6 }) {
          Text('深色模式')
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary);

          Toggle({ type: ToggleType.Switch, isOn: this.app.theme.isDark })
            .onChange(async (value: boolean) => {
              await this.setThemeBySwitch(value);
            });
        }
        .alignItems(HorizontalAlign.End);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Row({ space: 12 }) {
        this.buildInfoChip('状态保持', '已开启');
        this.buildInfoChip('当前主题', this.app.theme.isDark ? '深色' : '浅色');
      }
      .width('100%');

      Text('这里集中展示账号状态、专注成果与常用设置，后续同步能力也会从这里继续扩展。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(18)
    .borderRadius(24)
    .backgroundColor(this.app.theme.palette.surface);
  }

  build() {
    MainTabPageLayout({
      title: '我的',
    }) {
      PageScrollLayout({ space: 12, paddingTop: 12 }) {
        Row() {
          Blank();
          Column({ space: 12 }) {
            this.buildProfileCard();
            FocusStatsChart();
            ActivityHeatmap();
            SettingsPanel({
              onLogoutTap: async () => {
                await this.handleLogout();
              }
            });
          }
          .width('100%')
          .constraintSize({ maxWidth: 760 });
          Blank();
        }
        .width('100%');
      }
    }
  }
}
