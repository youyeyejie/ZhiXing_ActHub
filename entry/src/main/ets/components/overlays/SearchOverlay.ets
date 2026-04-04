/**
 * 搜索遮罩基类。
 * 支持页面遮罩、输入聚焦与关键字回调。
 */
@ComponentV2
export struct SearchOverlay {
  @Param isVisible: boolean = false;
  @Param placeholder: string = '搜索';
  @Param topInset: number = 56;
  @Event onDismiss: () => void = () => {};
  @Event onSearch: (keyword: string) => void = (_keyword: string) => {};

  @Local private keyword: string = '';
  @Local private maskOpacity: number = 0;

  aboutToAppear(): void {
    this.maskOpacity = 0;
    setTimeout(() => {
      this.maskOpacity = 1;
    }, 16);
  }

  private requestDismiss(): void {
    this.maskOpacity = 0;
    setTimeout(() => {
      this.onDismiss();
    }, 190);
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.isVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .opacity(this.maskOpacity)
          .animation({ duration: 220, curve: Curve.EaseOut, playMode: PlayMode.Normal })
          .onClick(() => {
            this.requestDismiss();
          });

        Column({ space: 10 }) {
          Row({ space: 10 }) {
            TextInput({ text: this.keyword, placeholder: this.placeholder })
              .layoutWeight(1)
              .height(44)
              .borderRadius(12)
              .backgroundColor('#FFFFFF')
              .padding({ left: 12, right: 12 })
              .defaultFocus(true)
              .onChange((value: string) => {
                this.keyword = value;
              })
              .onSubmit((_enterKey: EnterKeyType) => {
                this.onSearch(this.keyword);
              });

            Text('取消')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .onClick(() => {
                this.requestDismiss();
              });
          }
          .width('100%');

          Text('按回车触发搜索，点击遮罩或取消关闭。')
            .fontSize(12)
            .fontColor('#EAECF0');
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topInset, bottom: 12 });
      }
    }
    .width('100%')
    .height('100%');
  }
}
