import { PlanPage } from '../features/plan/pages/PlanPage';
import { TodoPage } from '../features/todo/pages/TodoPage';
import { FocusPage } from '../features/focus/pages/FocusPage';
import { IdeaPage } from '../features/idea/pages/IdeaPage';
import { UserPage } from '../features/user/pages/UserPage';

/**
 * 应用总壳层。
 * TODO: 后续在此接入启动流程、登录态分发、底部导航和全局 Overlay 容器。
 */
@Component
export struct AppShell {
  build() {
    Column({ space: 16 }) {
      Text('AppShell')
        .fontSize(20)
        .fontWeight(FontWeight.Bold);
      Text('TODO: 在此串联启动页、登录态分发、主标签页和全局浮层。')
        .fontSize(13)
        .fontColor('#666666');

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
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#F7F8FA');
  }
}
