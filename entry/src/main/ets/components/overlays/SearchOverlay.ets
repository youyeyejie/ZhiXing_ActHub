import { SearchResultItem, SearchScope, SearchService } from '../../core/services/SearchService';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 搜索基类页面。
 * 统一承接各页面搜索入口，并实时更新数据库搜索结果。
 */
@ComponentV2
export struct SearchOverlay {
  @Local private app: AppState = useAppState();
  @Param title: string = '搜索';
  @Param placeholder: string = '搜索';
  @Param scope: SearchScope = SearchScope.Plan;
  @Param topInset: number = 56;
  @Event onDismiss: () => void = () => {};
  @Event onSearch: (keyword: string) => void = (_keyword: string) => {};

  private searchService: SearchService = new SearchService();
  @Local private keyword: string = '';
  @Local private resultList: Array<SearchResultItem> = [];
  @Local private searching: boolean = false;
  @Local private requestVersion: number = 0;

  aboutToAppear(): void {
    this.performSearch('');
  }

  private async performSearch(keyword: string): Promise<void> {
    const version = this.requestVersion + 1;
    this.requestVersion = version;
    const normalized = keyword.trim();
    if (normalized.length === 0) {
      this.resultList = [];
      this.searching = false;
      return;
    }

    this.searching = true;
    const result = await this.searchService.search(this.scope, normalized);
    if (version !== this.requestVersion) {
      return;
    }

    this.resultList = result;
    this.searching = false;
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.app.theme.palette.background);

      Column({ space: 12 }) {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            TextInput({ text: this.keyword, placeholder: this.placeholder })
              .layoutWeight(1)
              .height(44)
              .borderRadius(12)
              .backgroundColor(this.app.theme.palette.surface)
              .padding({ left: 12, right: 12 })
              .defaultFocus(true)
              .placeholderColor(this.app.theme.palette.textTertiary)
              .caretColor(this.app.theme.palette.textTertiary)
              .fontColor(this.app.theme.palette.textPrimary)
              .onChange((value: string) => {
                this.keyword = value;
                this.onSearch(value);
                this.performSearch(value);
              })
              .onSubmit((_enterKey: EnterKeyType) => {
                this.onSearch(this.keyword);
                this.performSearch(this.keyword);
              });

            Text('取消')
              .fontSize(14)
              .fontColor(this.app.theme.palette.textSecondary)
              .onClick(() => {
                this.onDismiss();
              });
          }
          .width('100%');

          Text(this.title)
            .fontSize(13)
            .fontColor(this.app.theme.palette.textTertiary);
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topInset, bottom: 8 })
        .backgroundColor(this.app.theme.palette.background);

        Scroll() {
          Column({ space: 10 }) {
            if (this.searching) {
              Text('搜索中...')
                .fontSize(13)
                .fontColor(this.app.theme.palette.textTertiary);
            } else if (this.keyword.trim().length === 0) {
              Text('输入关键字开始搜索')
                .fontSize(13)
                .fontColor(this.app.theme.palette.textTertiary);
            } else if (this.resultList.length === 0) {
              Text('没有匹配结果')
                .fontSize(13)
                .fontColor(this.app.theme.palette.textTertiary);
            } else {
              ForEach(this.resultList, (item: SearchResultItem) => {
                Column({ space: 4 }) {
                  Text(item.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.app.theme.palette.textPrimary)
                    .width('100%');

                  Text(item.subtitle)
                    .fontSize(12)
                    .fontColor(this.app.theme.palette.textSecondary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%');
                }
                .width('100%')
                .padding(12)
                .borderRadius(12)
                .backgroundColor(this.app.theme.palette.surface);
              });
            }
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, bottom: 16 })
          .backgroundColor(this.app.theme.palette.background);
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.app.theme.palette.background);
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.app.theme.palette.background);
  }
}
