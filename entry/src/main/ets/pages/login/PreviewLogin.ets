import { LoginPage } from './index';

@Preview
@ComponentV2
struct PreviewLoginPage {
  build() {
    Column() {
      LoginPage();
    }
    .width('100%')
    .height('100%');
  }
}
