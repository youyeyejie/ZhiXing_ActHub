import { AppState, useAppState } from '../../app/AppStates';

/**
 * 详情卡片基础组件。
 * 使用 CustomDialog 承载内容，统一右上角关闭与系统返回的关闭行为。
 */
@CustomDialog
export struct DetailCard {
  controller?: CustomDialogController;
  onClose: () => void = () => {};
  @BuilderParam content: () => void = this.defaultContent;
  private app: AppState = useAppState();
  private dismissed: boolean = false;

  aboutToAppear(): void {
    this.dismissed = false;
  }

  aboutToDisappear(): void {
    if (this.dismissed) {
      return;
    }
    this.dismissed = true;
    this.onClose();
  }

  private requestDismiss(): void {
    if (this.dismissed) {
      return;
    }
    if (this.controller !== undefined) {
      this.controller.close();
      return;
    }
    this.dismissed = true;
    this.onClose();
  }

  @Builder
  private buildHeader() {
    Row() {
      Blank();

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('×')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textSecondary);
      }
      .width(32)
      .height(32)
      .backgroundColor(this.app.theme.palette.background)
      .onClick(() => {
        this.requestDismiss();
      });
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private defaultContent() {
    Column({ space: 8 }) {
      Text('DetailCard')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('在此承载详情信息与编辑内容。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    Column({ space: 10 }) {
    //   this.buildHeader();

      Column({ space: 10 }) {
        this.content();
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('80%')
    .height('60%')
    .padding(18)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface)
    .shadow({ radius: 16, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 6 });
  }
}
