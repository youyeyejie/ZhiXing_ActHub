import { SplashPage } from './index';

@Preview
@ComponentV2
struct PreviewSplashPage {
  build() {
    Column() {
      SplashPage();
    }
    .width('100%')
    .height('100%');
  }
}
