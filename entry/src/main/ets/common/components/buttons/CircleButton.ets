/**
 * 圆形按钮基类。
 * 统一新建按钮视觉与点击反馈。
 */
@Component
export struct CircleButton {
  @Prop icon: string = '+';
  @Prop text: string = '';
  @Prop buttonSize: number = 56;
  @Prop fillColor: string = '#0F172A';
  @Prop iconColor: string = '#FFFFFF';
  onTap: () => void = () => {};

  @State private isPressed: boolean = false;

  build() {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(this.buttonSize)
          .height(this.buttonSize)
          .fill(this.fillColor)
          .scale({ x: this.isPressed ? 0.94 : 1, y: this.isPressed ? 0.94 : 1 });

        Text(this.icon)
          .fontSize(this.buttonSize * 0.45)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.iconColor)
          .textAlign(TextAlign.Center)
          .maxLines(1);
      }
      .width(this.buttonSize)
      .height(this.buttonSize)
      .clip(true)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.isPressed = true;
          return;
        }

        if (event.type === TouchType.Up) {
          this.isPressed = false;
          this.onTap();
          return;
        }

        if (event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      });

      if (this.text.length > 0) {
        Text(this.text)
          .fontSize(12)
          .fontColor('#475467');
      }
    }
    .backgroundColor(Color.Transparent)
    .border({ width: 0 });
  }
}
