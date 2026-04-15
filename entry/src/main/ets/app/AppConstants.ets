export class AppConstants {
  static readonly APP_NAME: string = '知行';
  static readonly DATABASE_NAME: string = 'acthub.db';
  static readonly PREFERENCE_NAME: string = 'acthub.preference';
}

export class AppPreferenceKey {
  static readonly PREFERRED_THEME_MODE: string = 'preferredThemeMode';
  static readonly SESSION_USER_ID: string = 'sessionUserId';
  static readonly PLAN_REMINDER_ENABLED: string = 'planReminderEnabled';
}

export enum AppFlow {
  SPLASH = 'SPLASH',
  AUTH = 'AUTH',
  MAIN = 'MAIN'
}

export enum AppTab {
  PLAN = 'PLAN',
  TODO = 'TODO',
  IDEA = 'IDEA',
  USER = 'USER'
}

export class AppRoute {
  static readonly PLAN: string = 'plan';
  static readonly TODO: string = 'todo';
  static readonly IDEA: string = 'idea';
  static readonly USER: string = 'user';
  static readonly FOCUS: string = 'focusPage';
}

export class AppOverlayRoute {
  static readonly SEARCH: string = 'search';
  static readonly SHARED_TEST: string = 'sharedTest';
  static readonly ACTION_SHEET: string = 'actionSheet';
  static readonly DETAIL_CARD: string = 'detailCard';
  static readonly AI_INSIGHT: string = 'aiInsight';
}

export class SearchRouteParam {
  moduleName: string;
  pageTitle: string;

  constructor(moduleName: string, pageTitle: string) {
    this.moduleName = moduleName;
    this.pageTitle = pageTitle;
  }
}

export class FocusRouteParam {
}
