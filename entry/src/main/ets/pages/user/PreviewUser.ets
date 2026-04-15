import { UserPage } from './index';

@Preview
@ComponentV2
struct PreviewUserPage {
  build() {
    Column() {
      UserPage();
    }
    .width('100%')
    .height('100%');
  }
}
