import { AppState, useAppState } from '../../app/AppStates';
import { DetailCard } from '../../components/card/DetailCard';
/**
 * 详情目的页骨架。
 * 当前统一承载详情页路由，后续再由各模块替换成真实详情卡片或编辑页。
 */
@ComponentV2
export struct DetailPlaceholderPage {
  @Local private app: AppState = useAppState();
  @Param routeName: string = '';

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

  private resolveModuleName(): string {
    if (this.routeName === 'planDetail') {
      return 'plan';
    }
    if (this.routeName === 'todoDetail') {
      return 'todo';
    }
    if (this.routeName === 'ideaDetail') {
      return 'idea';
    }
    return 'unknown';
  }

  private resolveRecordId(): string {
    if (this.app.nav.detailRecordId.length > 0) {
      return this.app.nav.detailRecordId;
    }
    return '未提供';
  }

  build() {
    NavDestination() {
      Stack() {
        DetailCard({
          isVisible: true,
          onClose: () => {
            this.app.nav.back();
          }
        }) {
          Column({ space: 10 }) {
            Text(this.resolveTitle())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.app.theme.palette.textPrimary)
              .width('100%');

            Text('模块: ' + this.resolveModuleName())
              .fontSize(13)
              .fontColor(this.app.theme.palette.textSecondary)
              .width('100%');

            Text('记录 ID: ' + this.resolveRecordId())
              .fontSize(13)
              .fontColor(this.app.theme.palette.textSecondary)
              .width('100%');

            Text('已通过 openXXXDetail 路由打开统一 DetailCard。')
              .fontSize(13)
              .fontColor(this.app.theme.palette.textSecondary)
              .width('100%');
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%');
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
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
