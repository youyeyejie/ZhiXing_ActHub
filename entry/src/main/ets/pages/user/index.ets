import { ActivityHeatmap } from '../idea/components/ActivityHeatmap';
import { FocusStatsChart } from './components/FocusStatsChart';
import { SettingsPanel } from './components/SettingsPanel';
import { MainTabPageLayout } from '../../components/layout/MainTabPageLayout';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { PageScrollLayout } from "../../components/layout/PageScrollLayout";


/**
 * 组件功能简介：
 * - 我的页面骨架，组合统计与设置组件并提供测试入口。
 * - TODO: 尚未接入真实用户资料、设置持久化和完整统计数据。
 *
 * 可传入项：
 * - @Event onBottomBarVisibleChange: 通知父容器切换底部栏显隐。
 *
 * 返回行为：
 * - 返回主标签页布局并渲染用户中心测试内容。
 *
 * 副作用：
 * - 生命周期会触发底部栏显隐事件。
 * - 操作按钮会触发共享测试 overlay 路由。
 */
@ComponentV2
export struct UserPage {
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
   * 渲染我的页骨架。
   * TODO: 当前仍为测试组合，后续替换为真实用户信息与设置流程。
   */
  build() {
    MainTabPageLayout({
      title: '我的',
      actionText: '测试',
      onActionTap: () => {
        this.app.nav.pushOverlayByName(AppOverlayRoute.SHARED_TEST);
      }
    }) {
      Text("此页面目前组件均为测试，需要修改！")
      Text('TODO: 用户信息区与主题切换入口。')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary);
      PageScrollLayout({ space: 12, paddingTop: 12 }) {
        FocusStatsChart();
        ActivityHeatmap();
        SettingsPanel();
      }
    }
  }
}
