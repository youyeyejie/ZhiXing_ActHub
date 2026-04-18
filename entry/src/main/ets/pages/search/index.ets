import { AppTab, SearchRouteParam } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";
import { SearchResultItem, SearchScope, SearchService } from "../../core/services/SearchService";
import { PlanPageState, usePlanPageState } from "../plan/PlanPageState";
import { TodoPageState, useTodoPageState } from "../todo/TodoPageState";
import { PlanDetailCardContent } from "../plan/components/PlanDetailCardContent";
import { TodoDetailCardContent } from "../todo/components/TodoDetailCardContent";
import { Idea } from "../../core/models/Idea";
import { IdeaRepository } from "../../core/repositories/IdeaRepository";
import { IdeaDetailCardContent } from "../idea/components/IdeaDetailCardContent";
import { IdeaPageState, useIdeaPageState } from "../idea/IdeaPageState";
import { KeyboardAvoidMode } from "@kit.ArkUI";
import { SafeAreaUtils } from "../../core/theme/SafeAreaUtils";
import { SymbolGlyphModifier } from "@kit.ArkUI";

/**
 * 组件功能简介：
 * - 搜索页面，负责输入关键字并按模块范围查询与展示结果。
 *
 * 可传入项：
 * - @Param routeParam: 搜索来源模块与标题参数。
 * - @Param onRequestDismiss: 请求关闭当前搜索 overlay 的回调。
 *
 * 返回行为：
 * - 渲染搜索输入框与结果列表。
 *
 * 副作用：
 * - 会调用 SearchService 发起异步查询并更新本地结果状态。
 * - 生命周期会调整并恢复键盘避让模式。
 */
@ComponentV2
export struct SearchPage {
  @Local private app: AppState = useAppState();
  @Param routeParam: SearchRouteParam = new SearchRouteParam("", "搜索");
  @Param onRequestDismiss: () => void = () => {};

  private searchService: SearchService = new SearchService();
  private planState: PlanPageState = usePlanPageState();
  private todoState: TodoPageState = useTodoPageState();
  private ideaState: IdeaPageState = useIdeaPageState();
  private ideaRepository: IdeaRepository = new IdeaRepository();
  @Local private keyword: string = "";
  @Local private resultList: Array<SearchResultItem> = [];
  @Local private searching: boolean = false;
  @Local private requestVersion: number = 0;
  @Local private keyboardAvoidModeChanged: boolean = false;
  @Local private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
  }

  @Builder
  private buildPlanDetailContent() {
    PlanDetailCardContent();
  }

  @Builder
  private buildTodoDetailContent() {
    TodoDetailCardContent();
  }

  @Builder
  private buildIdeaDetailContent() {
    IdeaDetailCardContent();
  }

  /**
   * 页面出现时关闭键盘避让，避免 overlay 场景下产生额外顶起。
   */
  aboutToAppear(): void {
    this.disableKeyboardAvoid();
  }

  /**
   * 页面离开时恢复原键盘避让模式。
   */
  aboutToDisappear(): void {
    this.restoreKeyboardAvoid();
  }

  /**
   * 按模块返回搜索框提示文案。
   */
  private resolvePlaceholder(): string {
    if (this.routeParam.moduleName === "plan") {
      return "搜索日程内容/地点/描述";
    }
    if (this.routeParam.moduleName === "todo") {
      return "搜索待办内容/分类";
    }
    if (this.routeParam.moduleName === "idea") {
      return "搜索闪记标题/内容";
    }
    if (this.routeParam.moduleName === "focus") {
      return "搜索专注记录/时长";
    }
    if (this.routeParam.moduleName === "user") {
      return "搜索用户信息/设置";
    }
    return "输入关键字开始搜索";
  }

  /**
   * 将路由模块名映射为搜索域枚举。
   */
  private resolveScope(): SearchScope {
    if (this.routeParam.moduleName === "todo") {
      return SearchScope.Todo;
    }
    if (this.routeParam.moduleName === "idea") {
      return SearchScope.Idea;
    }
    if (this.routeParam.moduleName === "focus") {
      return SearchScope.Focus;
    }
    if (this.routeParam.moduleName === "user") {
      return SearchScope.User;
    }
    return SearchScope.Plan;
  }

  /**
   * 关闭键盘避让并缓存原状态。
   */
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

  /**
   * 恢复进入页面前的键盘避让模式。
   */
  private restoreKeyboardAvoid(): void {
    if (!this.keyboardAvoidModeChanged) {
      return;
    }
    try {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
    } catch (_error) {}
    this.keyboardAvoidModeChanged = false;
  }

  /**
   * 执行一次搜索请求并做版本竞态保护。
   */
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

  private openPlanDetailFromSearch(item: SearchResultItem): void {
    const recordId = this.normalizeId(item.id);
    if (recordId <= 0) {
      return;
    }
    this.app.nav.selectTab(AppTab.PLAN);
    this.app.nav.back(false);
    this.planState.openPlanDetail(recordId);
    this.app.nav.openDetailCard(this.buildPlanDetailContent);
  }

  private openTodoDetailFromSearch(item: SearchResultItem): void {
    const recordId = this.normalizeId(item.id);
    if (recordId <= 0) {
      return;
    }
    this.app.nav.selectTab(AppTab.TODO);
    this.app.nav.back(false);
    this.todoState.openTodoDetail(recordId);
    this.app.nav.openDetailCard(this.buildTodoDetailContent);
  }

  private async openIdeaDetailFromSearch(item: SearchResultItem): Promise<void> {
    const recordId = this.normalizeId(item.id);
    if (recordId <= 0) {
      return;
    }
    const found = await this.ideaRepository.findById(recordId);
    if (found === null) {
      return;
    }
    this.ideaState.openIdeaDetail(recordId);
    this.app.nav.selectTab(AppTab.IDEA);
    this.app.nav.back(false);
    this.app.nav.openDetailCard(this.buildIdeaDetailContent);
  }

  private handleSearchResultTap(item: SearchResultItem): void {
    if (item.scope === SearchScope.Plan) {
      this.openPlanDetailFromSearch(item);
      return;
    }
    if (item.scope === SearchScope.Todo) {
      this.openTodoDetailFromSearch(item);
      return;
    }
    if (item.scope === SearchScope.Idea) {
      this.openIdeaDetailFromSearch(item);
      return;
    }
    this.onRequestDismiss();
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === "undefined" || text === "null") {
      return "";
    }
    return text;
  }

  private hasDisplayText(value: string): boolean {
    return this.normalizeText(value).length > 0;
  }

  private joinDisplayParts(first: string, second: string): string {
    const parts: Array<string> = [];
    const firstPart = this.normalizeText(first);
    const secondPart = this.normalizeText(second);
    if (firstPart.length > 0) {
      parts.push(firstPart);
    }
    if (secondPart.length > 0) {
      parts.push(secondPart);
    }
    return parts.join(" · ");
  }

  private resolvePlanSecondaryText(item: SearchResultItem): string {
    return this.joinDisplayParts(item.timeText, item.locationText);
  }

  private resolveTodoSecondaryText(item: SearchResultItem): string {
    return this.joinDisplayParts(item.categoryText, item.statusText);
  }

  private hasKeyword(): boolean {
    return this.keyword.trim().length > 0;
  }

  private resolveHintText(): string {
    if (this.searching) {
      return "搜索中...";
    }
    if (!this.hasKeyword()) {
      return "输入关键字开始搜索";
    }
    return "没有匹配结果";
  }

  @Builder
  private buildTitleLine(value: string) {
    Text(value)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.app.theme.palette.textSecondary)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width("100%");
  }

  @Builder
  private buildMinorLine(value: string, maxLines: number) {
    Text(value)
      .fontSize(12)
      .fontColor(this.app.theme.palette.textTertiary)
      .maxLines(maxLines)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width("100%");
  }

  @Builder
  private buildTitleLineIfPresent(value: string) {
    if (this.hasDisplayText(value)) {
      this.buildTitleLine(this.normalizeText(value));
    }
  }

  @Builder
  private buildDescriptionLine(value: string) {
    if (this.hasDisplayText(value)) {
      this.buildMinorLine(this.normalizeText(value), 3);
    }
  }

  @Builder
  private buildSecondaryLine(value: string) {
    if (this.hasDisplayText(value)) {
      this.buildMinorLine(this.normalizeText(value), 2);
    }
  }

  @Builder
  private buildPlanResult(item: SearchResultItem) {
    Column({ space: 4 }) {
      this.buildTitleLineIfPresent(item.title)
      this.buildSecondaryLine(this.resolvePlanSecondaryText(item))
      this.buildDescriptionLine(item.descriptionText)
    }.width("100%");
  }

  @Builder
  private buildTodoResult(item: SearchResultItem) {
    Column({ space: 4 }) {
      this.buildTitleLineIfPresent(item.title)
      this.buildSecondaryLine(this.resolveTodoSecondaryText(item))
      this.buildDescriptionLine(item.descriptionText)
    }.width("100%");
  }

  @Builder
  private buildIdeaResult(item: SearchResultItem) {
    Column({ space: 4 }) {
      this.buildTitleLineIfPresent(item.title)
      this.buildDescriptionLine(item.descriptionText)
    }.width("100%");
  }

  @Builder
  private buildDefaultResult(item: SearchResultItem) {
    Column({ space: 4 }) {
      this.buildTitleLineIfPresent(item.title)
      this.buildSecondaryLine(item.subtitle)
      this.buildDescriptionLine(item.descriptionText)
    }.width("100%");
  }

  @Builder
  private buildResultItem(item: SearchResultItem) {
    if (item.scope === SearchScope.Plan) {
      this.buildPlanResult(item);
    } else if (item.scope === SearchScope.Todo) {
      this.buildTodoResult(item);
    } else if (item.scope === SearchScope.Idea) {
      this.buildIdeaResult(item);
    } else {
      this.buildDefaultResult(item);
    }
  }

  /**
   * 渲染搜索输入框与结果列表。
   */
  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column({ space: 12 }) {
        Search({ value: this.keyword, placeholder: this.resolvePlaceholder() })
          .searchIcon(
            new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'))
              .fontColor([this.app.theme.palette.textSecondary])
              .fontSize(16)
          )
          .cancelButton({
            style: CancelButtonStyle.INPUT,
            icon: new SymbolGlyphModifier($r('sys.symbol.xmark'))
              .fontColor([this.app.theme.palette.textSecondary])
              .fontSize(16)
          })
          .width("90%")
          .height(44)
          .borderRadius(12)
          .backgroundColor(this.app.theme.palette.surface)
          .padding({ left: 12, right: 12 })
          .margin({ left: 16, right: 16, bottom: 16, top: SafeAreaUtils.getTopInset() + 16 })
          .defaultFocus(true)
          .placeholderColor(this.app.theme.palette.textTertiary)
          .fontColor(this.app.theme.palette.textPrimary)
          .onChange((value: string) => {
            this.keyword = value;
            this.performSearch(value);
          })
          .onSubmit(() => {
            // 软键盘提交时不做额外处理，保持搜索结果不变。
          })

        Scroll() {
          Column({ space: 10 }) {
            if (this.searching || this.resultList.length === 0) {
              Column() {
                Text(this.resolveHintText())
                  .fontSize(13)
                  .fontColor(this.app.theme.palette.textTertiary)
                  .textAlign(TextAlign.Center)
              }
              .width("100%")
              .alignItems(HorizontalAlign.Center)
              .padding({ top: 28, bottom: 24 });
            } else {
              ForEach(this.resultList, (item: SearchResultItem) => {
                Column({ space: 6 }) {
                  this.buildResultItem(item)
                }
                .width("100%")
                .padding(12)
                .borderRadius(12)
                .backgroundColor(this.app.theme.palette.surface)
                .onClick(() => {
                  this.handleSearchResultTap(item);
                });
              });
            }
          }
          .width("100%")
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, bottom: 16, top: 8 })
        }
        .width("100%")
        .layoutWeight(1)
        .align(Alignment.Top)
      }.width("100%")
    }
    .width("100%")
    .height("100%");
  }
}
