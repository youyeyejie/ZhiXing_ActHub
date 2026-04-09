import { HitokotoCard } from './components/HitokotoCard';
import { IdeaCard } from './components/IdeaCard';
import { IdeaEditorSheet } from './components/IdeaEditorSheet';
import { ActivityHeatmap } from './components/ActivityHeatmap';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { PageScrollLayout } from '../../components/layout/PageScrollLayout';

/**
 * 组件功能简介：
 * - 闪记模块主页，组合一言、卡片、热力图和编辑入口测试组件。
 * - TODO: 尚未接入真实闪记数据、详情展开与搜索联动。
 *
 * 可传入项：
 * - @Event onBottomBarVisibleChange: 通知父容器切换底部栏显隐。
 *
 * 返回行为：
 * - 返回主标签页布局并渲染闪记模块内容区。
 *
 * 副作用：
 * - 生命周期会触发底部栏显隐事件。
 * - 操作按钮会触发 overlay 路由打开。
 */
@ComponentV2
export struct IdeaPage {
  @Local private app: AppState = useAppState();
  @Event onBottomBarVisibleChange: (visible: boolean) => void = (_visible: boolean): void => {};

  /**
   * 页面进入时请求显示底部导航栏。
   */
  aboutToAppear(): void {
    this.onBottomBarVisibleChange(true);
  }

  /**
   * 页面离开时保持底部导航栏可见。
   */
  aboutToDisappear(): void {
    this.onBottomBarVisibleChange(true);
  }

  /**
   * 渲染闪记模块测试骨架。
   * TODO: 当前组件多为占位，后续替换为真实数据流和详情交互。
   */
  build() {
    MainTabPageLayout({
      title: '闪记',
      actionIcon: $r('sys.symbol.magnifyingglass'),
      showFloatButton: true,
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('idea', '搜索闪记'));
      },
      onClickFloatingButton: () => {
        this.app.nav.openActionSheet();
      }
    }) {
      
      Text("此页面目前组件均为测试，需要修改！")
      PageScrollLayout({
        paddingBottom: 96
      }) {
        HitokotoCard();
        IdeaCard();
        ActivityHeatmap();
        IdeaEditorSheet();
      }
    }
  }
}
