import { AppTab } from '../../types/AppEnums';

/**
 * 主导航底栏骨架。
 * 当前阶段只负责五大主页面切换入口，视觉细节后续再统一收敛。
 */
@Component
export struct BottomTabBar {
  @Link currentTab: AppTab;
  onTabChange: (tab: AppTab) => void = (_tab: AppTab): void => {};

  @Builder
  private buildTabItem(tab: AppTab, label: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTab === tab ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === tab ? '#1F2329' : '#8A8F99');

      Row()
        .width(20)
        .height(3)
        .borderRadius(999)
        .backgroundColor(this.currentTab === tab ? '#1F2329' : '#FFFFFF');
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onTabChange(tab);
    });
  }

  build() {
    Row() {
      this.buildTabItem(AppTab.PLAN, '日程');
      this.buildTabItem(AppTab.TODO, '待办');
      this.buildTabItem(AppTab.FOCUS, '专注');
      this.buildTabItem(AppTab.IDEA, '闪记');
      this.buildTabItem(AppTab.USER, '我的');
      this.buildTabItem(AppTab.TEST, '测试');
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.SpaceBetween)
    .borderRadius(24)
    .backgroundColor('#FFFFFF');
  }
}
