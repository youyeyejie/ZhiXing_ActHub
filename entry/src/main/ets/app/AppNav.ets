import { AppTab } from './AppConstants';
import { PlanPage } from '../pages/plan';
import { TodoPage } from '../pages/todo';
import { FocusPage } from '../pages/focus';
import { IdeaPage } from '../pages/idea';
import { UserPage } from '../pages/user';
import { SharedInteractionTestPage } from '../pages/sharedtest';

/**
 * 应用主导航状态。
 * 基于 Navigation 控制器扩展应用级导航能力。
 * 当前 MVP 阶段负责维护底部标签页状态，并为后续子页路由预留统一入口。
 */
@ObservedV2
export class AppNav extends NavPathStack {
  @Trace private _tab: AppTab = AppTab.PLAN;

  get tab(): AppTab {
    return this._tab;
  }

  set tab(tab: AppTab) {
    this._tab = tab;
  }
}

/**
 * 应用首页当前标签页的内容构建入口。
 * 当前仅负责底部标签页对应主页内容的分发，不参与 Navigation 子页入栈。
 */
@Builder
export function buildCurrentPage(tab: AppTab) {
  if (tab === AppTab.PLAN) {
    PlanPage();
  } else if (tab === AppTab.TODO) {
    TodoPage();
  } else if (tab === AppTab.FOCUS) {
    FocusPage();
  } else if (tab === AppTab.IDEA) {
    IdeaPage();
  } else if (tab === AppTab.TEST) {
    SharedInteractionTestPage();
  } else {
    UserPage();
  }
}
