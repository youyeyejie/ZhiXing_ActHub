import { SearchRouteParam } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { SearchScope } from '../../core/services/SearchService';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { SearchOverlay } from '../../components/overlays/SearchOverlay';
import { NavDialogOverlay, NavDialogOverlayController } from '../../components/overlays/NavDialogOverlay';
/**
 * 搜索覆盖页路由容器。
 * 统一承接各模块通过 nav stack push 的搜索 overlay route。
 */
@ComponentV2
export struct SearchPlaceholderPage {
  @Local private app: AppState = useAppState();
  @Param routeParam: SearchRouteParam = new SearchRouteParam('', '搜索');
  private overlayController: NavDialogOverlayController = new NavDialogOverlayController();

  private resolveTitle(): string {
    if (this.routeParam.pageTitle.length > 0) {
      return this.routeParam.pageTitle;
    }
    return '搜索';
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

  build() {
    NavDialogOverlay({
      controller: this.overlayController,
      onDismiss: () => {
        this.app.nav.back(false);
      }
    }) {
      SearchOverlay({
        title: this.resolveTitle(),
        placeholder: this.resolvePlaceholder(),
        scope: this.resolveScope(),
        topInset: SafeAreaUtils.getSearchTopInset(),
        dismissController: this.overlayController
      });
    }
  }
}

@Builder
export function SearchPlaceholderPageBuilder(name: string, param: Object) {
  SearchPlaceholderPage({ routeParam: param as SearchRouteParam });
}
