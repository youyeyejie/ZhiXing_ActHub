import { AppState, useAppState } from '../../app/AppStates';
/**
 * 搜索目的页骨架。
 * 当前只承载统一的搜索路由结构，具体搜索交互后续在对应模块内实现。
 */
@ComponentV2
export struct SearchPlaceholderPage {
  @Local private app: AppState = useAppState();
  @Param routeName: string = '';
  @Local private pathStack: NavPathStack | undefined = undefined;

  private resolveTitle(): string {
    if (this.routeName === 'planSearch') {
      return '搜索日程';
    }
    if (this.routeName === 'todoSearch') {
      return '搜索待办';
    }
    if (this.routeName === 'ideaSearch') {
      return '搜索闪记';
    }
    return '搜索';
  }

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

        Text(this.resolveTitle())
          .fontSize(28)
          .fontWeight(FontWeight.Bold);

        Text('TODO: 在当前页面之上提供搜索遮罩、输入框和结果列表。')
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
export function SearchPlaceholderPageBuilder(name: string, _param: Object) {
  SearchPlaceholderPage({ routeName: name });
}
