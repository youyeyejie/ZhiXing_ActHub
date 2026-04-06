import { SearchRouteParam } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { SearchResultItem, SearchScope, SearchService } from '../../core/services/SearchService';
import { SafeAreaInsetLayout } from '../../components/layout/SafeAreaInsetLayout';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { NavDialogOverlayController } from '../../components/navigation/NavDialogOverlay';

/**
 * 搜索页面。
 * 在 pages 层实现搜索输入、结果渲染与模块范围切换。
 */
@ComponentV2
export struct SearchPage {
  @Local private app: AppState = useAppState();
  @Param routeParam: SearchRouteParam = new SearchRouteParam('', '搜索');
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

  private resolvePlaceholder(): string {
    if (this.routeParam.moduleName === 'plan') {
      return '搜索日程内容/地点/描述';
    }
    if (this.routeParam.moduleName === 'todo') {
      return '搜索待办内容/分类';
    }
    if (this.routeParam.moduleName === 'idea') {
      return '搜索闪记标题/内容';
    }
    if (this.routeParam.moduleName === 'focus') {
      return '搜索专注记录/时长';
    }
    if (this.routeParam.moduleName === 'user') {
      return '搜索用户信息/设置';
    }
    return '输入关键字开始搜索';
  }

  private resolveScope(): SearchScope {
    if (this.routeParam.moduleName === 'todo') {
      return SearchScope.Todo;
    }
    if (this.routeParam.moduleName === 'idea') {
      return SearchScope.Idea;
    }
    if (this.routeParam.moduleName === 'focus') {
      return SearchScope.Focus;
    }
    if (this.routeParam.moduleName === 'user') {
      return SearchScope.User;
    }
    return SearchScope.Plan;
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
    const result = await this.searchService.search(this.resolveScope(), normalized);
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
          fillHeight: false,
          surfaceColor: this.resolveHeaderBackgroundColor()
        }) {
          Column() {
            TextInput({ text: this.keyword, placeholder: this.resolvePlaceholder() })
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
