import { AppFlow, AppOverlayRoute, AppRoute } from "./AppConstants";
import { AppState, useAppState } from "./AppStates";
import { MainShell } from "./MainShell";
import { SplashPage } from "../pages/splash";
import { LoginPage } from "../pages/login";
import { SharedTestDestinationPage } from "../pages/sharedtest/SharedTestDestinationPage";
import { FocusOverlayDestination } from "../components/overlays/FocusOverlayDestination";
import { SearchOverlayDestination } from "../components/overlays/SearchOverlayDestination";
import { ActionSheetOverlayDestination } from "../components/overlays/ActionSheetOverlayDestination";
import { DetailCardOverlayDestination } from "../components/overlays/DetailCardOverlayDestination";
import { AIInsightOverlayDestination } from "../components/overlays/AIInsightOverlayDestination";
import { SearchRouteParam } from "./AppConstants";
import { ThemeMode } from "../core/theme/ThemeManager";

/**
 * 组件功能简介：
 * - 应用总壳层，负责在启动页、认证页、主页面之间分发。
 * - 承载 overlay 路由容器并根据路由名渲染对应目的页。
 *
 * 可传入项：
 * - 无（通过 AppState 与 AppStorage 读取全局状态）。
 *
 * 返回行为：
 * - 返回全屏 Stack，包含基础流程页面与可选的 Navigation overlay 容器。
 *
 * 副作用：
 * - `aboutToAppear` 与 `resolveBackgroundColor` 会同步主题偏好到全局状态。
 */
@ComponentV2
export struct AppShell {
  @Local private app: AppState = useAppState();

  /**
   * 当 overlay 缺少参数时创建兜底搜索参数。
   */
  private createFallbackSearchParam(routeName: string): SearchRouteParam {
    return new SearchRouteParam(routeName, "搜索");
  }

  /**
   * 从 NavPathStack 读取搜索页 push 时携带的真实 SearchRouteParam。
   * 若读不到则回退为默认值。
   */
  private resolveSearchRouteParam(): SearchRouteParam {
    const params: SearchRouteParam[] = this.app.nav.getParamByName(
      AppOverlayRoute.SEARCH,
    ) as SearchRouteParam[];
    if (params.length > 0) {
      return params[params.length - 1];
    }
    return this.createFallbackSearchParam("");
  }

  private readPreferredThemeMode(): ThemeMode {
    const value: Object | undefined = AppStorage.get("preferredThemeMode");
    if (value === ThemeMode.DARK) {
      return ThemeMode.DARK;
    }
    if (value === ThemeMode.LIGHT) {
      return ThemeMode.LIGHT;
    }
    return ThemeMode.SYSTEM;
  }

  /**
   * 读取系统深色状态缓存。
   */
  private readSystemDarkMode(): boolean {
    const value: Object | undefined = AppStorage.get("systemDarkMode");
    return value === true;
  }

  /**
   * 页面出现时主动同步主题，避免冷启动闪烁。
   */
  aboutToAppear(): void {
    this.app.applyThemePreference(this.readPreferredThemeMode(), this.readSystemDarkMode());
  }

  /**
   * 计算并返回壳层背景色。
   */
  private resolveBackgroundColor(): ResourceColor {
    this.app.applyThemePreference(this.readPreferredThemeMode(), this.readSystemDarkMode());
    return this.app.theme.palette.background;
  }

  @Builder
  /**
   * 渲染基础流程页面（启动/认证/主流程）。
   */
  private buildBaseContent() {
    if (this.app.flow === AppFlow.SPLASH) {
      SplashPage();
    } else if (this.app.flow === AppFlow.AUTH) {
      LoginPage();
    } else {
      MainShell();
    }
  }

  @Builder
  /**
   * 根据 route 名渲染对应 overlay 目的页。
   */
  private buildDestination(name: string) {
    if (name === AppRoute.FOCUS) {
      FocusOverlayDestination();
    } else if (name === AppOverlayRoute.SEARCH) {
      SearchOverlayDestination({ routeParam: this.resolveSearchRouteParam() });
    } else if (name === AppOverlayRoute.ACTION_SHEET) {
      ActionSheetOverlayDestination({ content: this.app.nav.actionSheetContentBuilder });
    } else if (name === AppOverlayRoute.DETAIL_CARD) {
      DetailCardOverlayDestination({ content: this.app.nav.detailCardContentBuilder });
    } else if (name === AppOverlayRoute.SHARED_TEST) {
      SharedTestDestinationPage();
    } else if (name === AppOverlayRoute.AI_INSIGHT) {
      AIInsightOverlayDestination();
    } else {
      SearchOverlayDestination({
        routeParam: this.createFallbackSearchParam(this.app.nav.mainRouteName),
      });
    }
  }

  /**
   * 渲染应用壳层和 overlay 容器。
   */
  build() {
    Stack() {
      this.buildBaseContent()

      if (this.app.nav.hasOverlayRoute) {
        Navigation(this.app.nav) {}
          .mode(NavigationMode.Stack)
          .hideNavBar(true)
          .navDestination(this.buildDestination)
          .backgroundColor(this.app.theme.palette.transparent)
          .width("100%")
          .height("100%");
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.resolveBackgroundColor());
  }
}
