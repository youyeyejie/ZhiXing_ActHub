import { AppState, useAppState } from '../../app/AppStates';
import { SearchRouteParam } from '../../app/AppConstants';
/**
 * 搜索目的页骨架。
 * 当前只承载统一的搜索路由结构，具体搜索交互后续在对应模块内实现。
 */
@ComponentV2
export struct SearchPlaceholderPage {
  @Local private app: AppState = useAppState();
  @Param routeParam: SearchRouteParam = new SearchRouteParam('', '搜索');
  @Local private pathStack: NavPathStack | undefined = undefined;

  private resolveTitle(): string {
    if (this.routeParam.pageTitle.length > 0) {
      return this.routeParam.pageTitle;
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
          .fontColor(this.app.theme.palette.textSecondary);
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .padding(20)
      .backgroundColor(this.app.theme.palette.background);
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
export function SearchPlaceholderPageBuilder(name: string, param: Object) {
  SearchPlaceholderPage({ routeParam: param as SearchRouteParam });
}
