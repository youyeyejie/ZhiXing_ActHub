/**
 * 通用圆环组件。
 * 基于 Canvas 绘制轨道与进度弧线。
 */
@Component
export struct CircularProgress {
  @Watch('handleProgressChanged')
  @Prop progress: number = 0.72;
  @Watch('handleProgressChanged')
  @Prop diameter: number = 180;
  @Watch('handleProgressChanged')
  @Prop strokeWidth: number = 12;
  @Watch('handleProgressChanged')
  @Prop progressColor: string = '#0EA5E9';
  @Watch('handleProgressChanged')
  @Prop trackColor: string = '#E2E8F0';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context2D: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

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
    this.context2D.strokeStyle = this.trackColor;
    this.context2D.arc(center, center, radius, 0, Math.PI * 2);
    this.context2D.stroke();

    this.context2D.beginPath();
    this.context2D.strokeStyle = this.progressColor;
    this.context2D.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * value);
    this.context2D.stroke();
  }

  private handleProgressChanged(): void {
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
        .fontColor('#0F172A');
    }
    .width(this.diameter)
    .height(this.diameter);
  }
}
