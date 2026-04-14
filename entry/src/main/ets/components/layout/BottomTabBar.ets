import { AppTab } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 主导航底栏组件，包含四个标签入口和中间专注入口。
 *
 * 可传入项：
 * - @Param currentTab: 当前激活标签。
 * - @Event onTabChange: 点击标签时回调。
 * - @Event onFocusTap: 点击中间专注入口时回调。
 *
 * 返回行为：
 * - 返回底部导航栏布局。
 *
 * 副作用：
 * - 点击事件会触发外部标签切换与专注入口回调。
 */
@ComponentV2
export struct BottomTabBar {
  @Local private app: AppState = useAppState();
  @Param currentTab: AppTab = AppTab.PLAN;
  @Event onTabChange: (tab: AppTab) => void = (_tab: AppTab): void => {};
  @Event onFocusTap: () => void = (): void => {};

  @Builder
  private buildTabItem(tab: AppTab, label: string, icon: Resource) {
    Column({ space: 6 }) {
      SymbolGlyph(icon)
        .fontSize(18)
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        .fontColor([
          this.currentTab === tab ? this.app.theme.palette.textPrimary : this.app.theme.palette.textSecondary
        ])

      Text(label)
        .fontSize(12)
        .fontWeight(this.currentTab === tab ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === tab ? this.app.theme.palette.textPrimary : this.app.theme.palette.textSecondary);

      Row()
        .width(20)
        .height(3)
        .borderRadius(999)
        .backgroundColor(this.currentTab === tab ? this.app.theme.palette.primary : this.app.theme.palette.surface);
    }
    .layoutWeight(1)
    .padding({ top: 4, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onTabChange(tab);
    });
  }

  @Builder
  private buildFocusAction() {
    Column({ space: 6 }) {
      Row() {
        Image($r(this.app.theme.palette.logo))
      }
      .width(70)
      .height(70)
      .borderRadius(35)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.app.theme.palette.primary);
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
      this.buildTabItem(AppTab.PLAN, '日程', $r('sys.symbol.calendar'));
      this.buildTabItem(AppTab.TODO, '待办', $r('sys.symbol.checkmark_circle'));
      this.buildFocusAction(); // 专注入口
      this.buildTabItem(AppTab.IDEA, '闪记', $r('sys.symbol.lightbulb'));
      this.buildTabItem(AppTab.USER, '我的', $r('sys.symbol.person'));
    }
    .height(60)
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.SpaceBetween)
    .borderRadius(24)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
