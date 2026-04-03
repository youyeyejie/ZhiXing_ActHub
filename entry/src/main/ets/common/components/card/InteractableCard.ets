/**
 * 可交互卡片基类占位组件。
 * TODO: 后续补充圆角、阴影、手势监听和左右滑动回调能力。
 */
@Component
export struct InteractableCard {
  build() {
    Column({ space: 8 }) {
      Text('InteractableCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 在此封装通用卡片样式与手势交互。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
