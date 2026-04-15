import { AppConstants } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';

@ComponentV2
export struct SplashPage {
  @Local private app: AppState = useAppState();
  @Local private hasStarted: boolean = false;
  @Local private statusText: string = '正在准备应用...';

  aboutToAppear(): void {
    if (this.hasStarted) {
      return;
    }
    this.hasStarted = true;
    this.beginBootstrap();
  }

  private async beginBootstrap(): Promise<void> {
    try {
      this.statusText = '正在加载本地数据...';
      await this.delay(260);
      this.statusText = '正在恢复登录状态...';
      await this.delay(180);
      await this.app.bootstrap();
    } catch (_error) {
      this.app.enterAuth();
    }
  }

  private delay(duration: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(resolve, duration);
    });
  }

  private resolveLogo(): Resource {
    return $r('app.media.foreground');
  }

  build() {
    Column({ space: 20 }) {
      Column({ space: 16 }) {
        Column() {
          Image(this.resolveLogo())
            .width(88)
            .height(88)
            .objectFit(ImageFit.Contain);
        }
        .width(132)
        .height(132)
        .borderRadius(32)
        .backgroundColor(this.app.theme.palette.surface)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Text('知行')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.app.theme.palette.textPrimary);

        Text('计划、待办、专注与闪记，在同一个空间里流动')
          .fontSize(14)
          .fontColor(this.app.theme.palette.textSecondary)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .constraintSize({ maxWidth: 420 });

      LoadingProgress()
        .width(28)
        .height(28)
        .color(this.app.theme.palette.primary);

      Text(this.statusText)
        .fontSize(13)
        .fontColor(this.app.theme.palette.textTertiary);

      Text(AppConstants.APP_NAME)
        .fontSize(12)
        .fontColor(this.app.theme.palette.textTertiary);
    }
    .width('100%')
    .height('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.app.theme.palette.background);
  }
}
