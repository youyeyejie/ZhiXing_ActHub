import { AppState, useAppState } from '../../app/AppStates';

/**
 * 通用圆环组件。
 * 基于 Canvas 绘制轨道与进度弧线。
 */
@ComponentV2
export struct CircularProgress {
  @Local private app: AppState = useAppState();
  @Param progress: number = 0.72;
  @Param diameter: number = 180;
  @Param strokeWidth: number = 12;
  @Param progressColor: string = '';
  @Param trackColor: string = '';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context2D: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  @Computed
  private get effectiveProgressColor(): string {
    return this.progressColor.length > 0 ? this.progressColor : this.app.theme.palette.primary;
  }

  @Computed
  private get effectiveTrackColor(): string {
    return this.trackColor.length > 0 ? this.trackColor : this.app.theme.palette.surfaceSecondary;
  }

  private draw(): void {
    const totalSize: number = Math.max(80, this.diameter);
    const line: number = Math.max(4, this.strokeWidth);
    const center: number = totalSize / 2;
    const radius: number = center - line;
    const value: number = Math.max(0, Math.min(1, this.progress));

    this.context2D.clearRect(0, 0, totalSize, totalSize);
    this.context2D.lineWidth = line;
    this.context2D.lineCap = 'round';

    this.context2D.beginPath();
    this.context2D.strokeStyle = this.effectiveTrackColor;
    this.context2D.arc(center, center, radius, 0, Math.PI * 2);
    this.context2D.stroke();

    this.context2D.beginPath();
    this.context2D.strokeStyle = this.effectiveProgressColor;
    this.context2D.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * value);
    this.context2D.stroke();
  }

  @Monitor('progress', 'diameter', 'strokeWidth', 'progressColor', 'trackColor', 'effectiveProgressColor', 'effectiveTrackColor')
  private handleParamsChanged(): void {
    this.draw();
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.context2D)
        .width(this.diameter)
        .height(this.diameter)
        .onReady(() => {
          this.draw();
        })
        .onAreaChange(() => {
          this.draw();
        });

      Text((Math.round(Math.max(0, Math.min(1, this.progress)) * 100)).toString() + '%')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.app.theme.palette.textPrimary);
    }
    .width(this.diameter)
    .height(this.diameter);
  }
}
