import { AppTab, SearchRouteParam } from "../../app/AppConstants";
import { AppState, useAppState } from "../../app/AppStates";
import { SearchResultItem, SearchScope, SearchService } from "../../core/services/SearchService";
import { PlanPageState, usePlanPageState } from "../plan/PlanPageState";
import { TodoPageState, useTodoPageState } from "../todo/TodoPageState";
import { PlanDetailOverlay } from "../plan/components/PlanDetailOverlay";
import { TodoDetailOverlay } from "../todo/components/TodoDetailOverlay";
import { Idea } from "../../core/models/Idea";
import { IdeaRepository } from "../../core/repositories/IdeaRepository";
import { IdeaEditorSheet } from "../idea/components/IdeaEditorSheet";
import { IdeaPageState, useIdeaPageState } from "../idea/IdeaPageState";
import { KeyboardAvoidMode } from "@kit.ArkUI";
import { SafeAreaUtils } from "../../core/theme/SafeAreaUtils";

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

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  @Builder
  private buildPlanDetailContent() {
    PlanDetailOverlay();
  }

  @Builder
  private buildTodoDetailContent() {
    TodoDetailOverlay();
  }

  @Builder
  private buildIdeaDetailContent() {
    IdeaEditorSheet({
      hideInnerHeader: true,
    });
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
    if (recordId.length === 0) {
      return;
    }
    this.app.nav.selectTab(AppTab.PLAN);
    this.app.nav.back(false);
    this.planState.openPlanDetail(recordId);
    this.app.nav.openDetailCard(this.buildPlanDetailContent, '编辑日程');
  }

  private openTodoDetailFromSearch(item: SearchResultItem): void {
    const recordId = this.normalizeId(item.id);
    if (recordId.length === 0) {
      return;
    }
    this.app.nav.selectTab(AppTab.TODO);
    this.app.nav.back(false);
    this.todoState.openTodoDetail(recordId);
    this.app.nav.openDetailCard(this.buildTodoDetailContent, '编辑待办');
  }

  private async openIdeaDetailFromSearch(item: SearchResultItem): Promise<void> {
    const recordId = this.normalizeId(item.id);
    if (recordId.length === 0) {
      return;
    }
    const found = await this.ideaRepository.findById(recordId);
    if (found === null) {
      return;
    }
    this.ideaState.openIdeaDetail(recordId);
    this.app.nav.selectTab(AppTab.IDEA);
    this.app.nav.back(false);
    this.app.nav.openDetailCard(this.buildIdeaDetailContent, '编辑闪记');
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

  /**
   * 渲染搜索输入框与结果列表。
   */
  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column({ space: 12 }) {
          Search({ value: this.keyword, placeholder: this.resolvePlaceholder() })
            .searchIcon({
              src: $r("sys.media.ohos_ic_public_search_filled"),
            })
            .cancelButton({
              style: CancelButtonStyle.CONSTANT,
              icon: {
                src: $r("sys.media.ohos_ic_public_cancel_filled"),
              },
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
            if (this.searching) {
              Text("搜索中...").fontSize(13).fontColor(this.app.theme.palette.textTertiary);
            } else if (this.resultList.length === 0) {
              Text("没有匹配结果").fontSize(13).fontColor(this.app.theme.palette.textTertiary);
            } else {
              ForEach(this.resultList, (item: SearchResultItem) => {
                Column({ space: 4 }) {
                  Text(item.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.app.theme.palette.textPrimary)
                    .width("100%")
                  Text(item.subtitle)
                    .fontSize(12)
                    .fontColor(this.app.theme.palette.textSecondary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width("100%")
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
