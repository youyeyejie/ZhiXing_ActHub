import { FocusPage } from '../focus';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 专注页路由容器。
 * 当前先作为全屏目的页承载专注模块，后续再补沉浸式控制栏和状态同步。
 */
@ComponentV2
export struct FocusDestinationPage {
  @Local private app: AppState = useAppState();
  @Local private pathStack: NavPathStack | undefined = undefined;

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Row() {
          Button('返回')
            .type(ButtonType.Normal)
            .onClick(() => {
              this.app.nav.back();
            });

          Blank();
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 20, right: 20, top: 16 });

        FocusPage();
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA');
    }
    .width('100%')
    .height('100%')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed(() => {
      this.app.nav.back();
      return true;
    });
  }
}

@Builder
export function FocusDestinationPageBuilder(_name: string, _param: Object) {
  FocusDestinationPage();
}
