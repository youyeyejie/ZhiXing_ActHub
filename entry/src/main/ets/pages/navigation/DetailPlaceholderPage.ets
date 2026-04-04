import { AppState, useAppState } from '../../app/AppStates';
/**
 * 详情目的页骨架。
 * 当前统一承载详情页路由，后续再由各模块替换成真实详情卡片或编辑页。
 */
@ComponentV2
export struct DetailPlaceholderPage {
  @Local private app: AppState = useAppState();
  @Param routeName: string = '';
  @Local private pathStack: NavPathStack | undefined = undefined;

  private resolveTitle(): string {
    if (this.routeName === 'planDetail') {
      return '日程详情';
    }
    if (this.routeName === 'todoDetail') {
      return '待办详情';
    }
    if (this.routeName === 'ideaDetail') {
      return '闪记详情';
    }
    return '详情';
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

        Text('TODO: 详情信息、编辑区和删除撤销反馈后续在此接入。')
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
export function DetailPlaceholderPageBuilder(name: string, _param: Object) {
  DetailPlaceholderPage({ routeName: name });
}
