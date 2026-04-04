import { AppState, useAppState } from '../../app/AppStates';
/**
 * 设置页骨架。
 * 当前用于承载从“我的”进入的系统设置类页面，具体设置项后续逐步迁入。
 */
@ComponentV2
export struct SettingsPlaceholderPage {
  @Local private app: AppState = useAppState();
  @Local private pathStack: NavPathStack | undefined = undefined;

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Row() {
          Button('返回')
            .type(ButtonType.Normal)
            .onClick(() => {
              this.app.nav.back();
            });
          Blank();
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween);

        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold);

        Text('TODO: 深浅色模式、提醒开关、导入导出和退出登录后续在此集中实现。')
          .fontSize(14)
          .fontColor('#666666');
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .padding(20)
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
export function SettingsPlaceholderPageBuilder(_name: string, _param: Object) {
  SettingsPlaceholderPage();
}
