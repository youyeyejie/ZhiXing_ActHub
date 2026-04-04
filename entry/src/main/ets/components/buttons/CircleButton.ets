import { AppState, useAppState } from '../../app/AppStates';

/**
 * 圆形按钮基类。
 * 统一新建按钮视觉与点击反馈。
 */
@ComponentV2
export struct CircleButton {
  @Local private app: AppState = useAppState();
  @Param icon: string = '+';
  @Param text: string = '';
  @Param buttonSize: number = 56;
  @Param fillColor: string = '';
  @Param iconColor: string = '';
  @Event onTap: () => void = () => {};

  @Local private isPressed: boolean = false;

  build() {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(this.buttonSize)
          .height(this.buttonSize)
          .fill(this.fillColor.length > 0 ? this.fillColor : this.app.theme.palette.primary)
          .scale({ x: this.isPressed ? 0.94 : 1, y: this.isPressed ? 0.94 : 1 });

        Text(this.icon)
          .fontSize(this.buttonSize * 0.45)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.iconColor.length > 0 ? this.iconColor : this.app.theme.palette.surface)
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
          .fontColor(this.app.theme.palette.textSecondary);
      }
    }
    .backgroundColor(Color.Transparent)
    .border({ width: 0 });
  }
}
