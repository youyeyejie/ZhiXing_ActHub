import { PlanPage } from '../features/plan/pages/PlanPage';
import { TodoPage } from '../features/todo/pages/TodoPage';
import { FocusPage } from '../features/focus/pages/FocusPage';
import { IdeaPage } from '../features/idea/pages/IdeaPage';
import { UserPage } from '../features/user/pages/UserPage';
import { SharedInteractionTestPage } from '../features/sharedtest/pages/SharedInteractionTestPage';
import display from '@ohos.display';

/**
 * 应用总壳层。
 * TODO: 后续在此接入启动流程、登录态分发、底部导航和全局 Overlay 容器。
 */
@Component
export struct AppShell {
  @State private topInset: number = 30;
  @State private bottomInset: number = 12;

  aboutToAppear(): void {
    this.applySafeInsets();
  }

  private applySafeInsets(): void {
    try {
      const info = display.getDefaultDisplaySync();
      const longEdge = Math.max(info.width, info.height);
      const shortEdge = Math.max(1, Math.min(info.width, info.height));
      const ratio = longEdge / shortEdge;

      if (ratio >= 2.18) {
        this.topInset = 48;
        this.bottomInset = 22;
      } else if (ratio >= 2.0) {
        this.topInset = 40;
        this.bottomInset = 18;
      } else {
        this.topInset = 30;
        this.bottomInset = 12;
      }
    } catch (_error) {
      this.topInset = 32;
      this.bottomInset = 12;
    }
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          PlanPage();
        }
        .tabBar('日程');

        TabContent() {
          TodoPage();
        }
        .tabBar('待办');

        TabContent() {
          FocusPage();
        }
        .tabBar('专注');

        TabContent() {
          IdeaPage();
        }
        .tabBar('闪记');

        TabContent() {
          UserPage();
        }
        .tabBar('我的');

        TabContent() {
          SharedInteractionTestPage();
        }
        .tabBar('测试');
      }
      .scrollable(false)
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.topInset, bottom: this.bottomInset })
    .backgroundColor('#F7F8FA');
  }
}
