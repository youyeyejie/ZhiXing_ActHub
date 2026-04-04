import { AppState, useAppState } from '../../../app/AppStates';
import { ThemeMode } from '../../../core/theme/ThemeManager';

/**
 * 设置面板骨架。
 * TODO: 后续放入主题切换、提醒开关、导入导出和退出登录入口。
 */
@ComponentV2
export struct SettingsPanel {
  @Local private app: AppState = useAppState();

  build() {
    Column({ space: 8 }) {
      Text('SettingsPanel')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);
      Text('TODO: 汇总系统设置项。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);

      Row({ space: 8 }) {
        Button('浅色')
          .fontSize(12)
          .onClick(() => {
            this.app.theme.set(ThemeMode.LIGHT);
          });

        Button('深色')
          .fontSize(12)
          .onClick(() => {
            this.app.theme.set(ThemeMode.DARK);
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
