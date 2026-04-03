/**
 * 底部导航栏占位组件。
 * TODO: 后续统一处理五大主页面切换与专注入口凸显样式。
 */
@Component
export struct BottomTabBar {
  build() {
    Row({ space: 16 }) {
      Text('日程');
      Text('待办');
      Text('专注');
      Text('闪记');
      Text('我的');
    }
    .width('100%')
    .padding(16)
    .justifyContent(FlexAlign.SpaceAround)
    .borderRadius(24)
    .backgroundColor('#FFFFFF');
  }
}
