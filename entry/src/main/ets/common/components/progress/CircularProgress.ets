/**
 * 通用圆环组件占位。
 * TODO: 后续基于 Canvas 实现进度、颜色、粗细和动画参数。
 */
@Component
export struct CircularProgress {
  build() {
    Column({ space: 8 }) {
      Text('CircularProgress')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 在此绘制可复用圆环。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width(180)
    .height(180)
    .justifyContent(FlexAlign.Center)
    .borderRadius(90)
    .backgroundColor('#EDEFF2');
  }
}
