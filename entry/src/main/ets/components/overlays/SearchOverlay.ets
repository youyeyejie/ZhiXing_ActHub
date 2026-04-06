import { SearchResultItem, SearchScope, SearchService } from '../../core/services/SearchService';
import { AppState, useAppState } from '../../app/AppStates';
import { SafeAreaInsetLayout } from '../layout/SafeAreaInsetLayout';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { NavDialogOverlayController } from './NavDialogOverlay';

/**
 * 搜索基类页面。
 * 统一承接各页面搜索入口，并实时更新数据库搜索结果。
 */
@ComponentV2
export struct SearchOverlay {
  @Local private app: AppState = useAppState();
  @Param placeholder: string = '搜索';
  @Param scope: SearchScope = SearchScope.Plan;
  @Param dismissController: NavDialogOverlayController = new NavDialogOverlayController();

  private searchService: SearchService = new SearchService();
  @Local private keyword: string = '';
  @Local private resultList: Array<SearchResultItem> = [];
  @Local private searching: boolean = false;
  @Local private requestVersion: number = 0;
  @Local private keyboardAvoidModeChanged: boolean = false;
  @Local private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;

  aboutToAppear(): void {
    this.disableKeyboardAvoid();
    this.performSearch('');
  }

  aboutToDisappear(): void {
    this.restoreKeyboardAvoid();
  }

  private resolveOverlayBackgroundColor(): string {
    if (this.keyword.trim().length > 0) {
      return this.app.theme.palette.background;
    }
    return this.app.theme.palette.searchOverlayMask;
  }

  private resolveHeaderBackgroundColor(): string {
    return this.app.theme.palette.background;
  }

  private disableKeyboardAvoid(): void {
    try {
      const uiContext = this.getUIContext();
      this.previousKeyboardAvoidMode = uiContext.getKeyboardAvoidMode();
      uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
      this.keyboardAvoidModeChanged = true;
    } catch (_error) {
      this.keyboardAvoidModeChanged = false;
    }
  }

  private restoreKeyboardAvoid(): void {
    if (!this.keyboardAvoidModeChanged) {
      return;
    }
    try {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
    } catch (_error) {
    }
    this.keyboardAvoidModeChanged = false;
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
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.resolveOverlayBackgroundColor());

      Column({ space: 12 }) {
        SafeAreaInsetLayout({
          includeTop: true,
          extraTop: 20,
          surfaceColor: this.resolveHeaderBackgroundColor()
        }) {
          Column() {
            TextInput({ text: this.keyword, placeholder: this.placeholder })
              .width('100%')
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
                this.performSearch(value);
              })
              .onSubmit((_enterKey: EnterKeyType) => {
                this.performSearch(this.keyword);
              });
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 });
        }

        Scroll() {
          Column({ space: 10 }) {
            if (this.searching) {
              Text('搜索中...')
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
          .padding({ left: 16, right: 16, bottom: 16 });
        }
        .width('100%')
        .layoutWeight(1)
        .onClick(() => {
          this.dismissController.dismiss();
        });
      }
      .width('100%');
    }
    .width('100%')
    .height('100%');
  }
}
