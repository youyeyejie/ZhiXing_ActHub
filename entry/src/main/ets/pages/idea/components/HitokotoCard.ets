import { AppState, useAppState } from "../../../app/AppStates";
import { HitokotoService } from "../../../core/services/HitokotoService";

/**
 * 一言卡片组件。
 * 显示随机推荐句子，支持点击刷新。
 */
@ComponentV2
export struct HitokotoCard {
  @Local private app: AppState = useAppState();

  private service: HitokotoService = new HitokotoService();
  @Local private sentence: string = "点击获取一句话...";
  @Local private loading: boolean = false;

  aboutToAppear(): void {
    this.loadSentence();
  }

  /**
   * 加载一言句子。
   */
  private async loadSentence(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    try {
      this.sentence = await this.service.fetchSentence();
    } catch (_error) {
      this.sentence = "愿你今天有好心情";
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text("「")
          .fontSize(18)
          .fontColor(this.app.theme.palette.primary)
        Text(this.sentence)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Text("」")
          .fontSize(18)
          .fontColor(this.app.theme.palette.primary)
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.loadSentence();
      });
    }
    .width("100%")
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface)
    .onClick(() => {
      if (!this.loading) {
        this.loadSentence();
      }
    });
  }
}
