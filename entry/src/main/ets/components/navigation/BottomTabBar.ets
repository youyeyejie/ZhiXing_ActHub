import { AppTab } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 主导航底栏骨架。
 * 当前阶段采用四个主标签页加中间专注入口的结构。
 */
@ComponentV2
export struct BottomTabBar {
  @Local private app: AppState = useAppState();
  @Param currentTab: AppTab = AppTab.PLAN;
  @Event onTabChange: (tab: AppTab) => void = (_tab: AppTab): void => {};
  @Event onFocusTap: () => void = (): void => {};

  @Builder
  private buildTabItem(tab: AppTab, label: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTab === tab ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === tab ? this.app.theme.palette.textPrimary : this.app.theme.palette.textSecondary);

      Row()
        .width(20)
        .height(3)
        .borderRadius(999)
        .backgroundColor(this.currentTab === tab ? this.app.theme.palette.primary : this.app.theme.palette.surface);
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onTabChange(tab);
    });
  }

  @Builder
  private buildFocusAction() {
    Column({ space: 6 }) {
      Row() {
        Image($r("app.media.foreground"))
      }
      .width(60)
      .height(60)
      .borderColor(this.app.theme.palette.primary)
      .borderWidth(5)
      .borderRadius(30)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.app.theme.palette.surfaceSecondary);
    }
    .padding({ top: 2, left: 8, right: 8 })
    .alignItems(HorizontalAlign.Center)
    .offset({y:-20})
    .onClick(() => {
      this.onFocusTap();
    });
  }

  build() {
    Row() {
      this.buildTabItem(AppTab.PLAN, '日程');
      this.buildTabItem(AppTab.TODO, '待办');
      this.buildFocusAction(); // 专注入口
      this.buildTabItem(AppTab.IDEA, '闪记');
      this.buildTabItem(AppTab.USER, '我的');
    }
    .height(60)
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.SpaceBetween)
    .borderRadius(24)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
