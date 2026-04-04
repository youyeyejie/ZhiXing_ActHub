import { ThemeManager } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';
import { AppFlow } from './AppConstants';

@ObservedV2
export class AppState {
  private themeManager: ThemeManager = new ThemeManager();
  private _nav: AppNav = new AppNav();
  @Trace public flow: AppFlow = AppFlow.MAIN;

  get theme(): ThemeManager {
    return this.themeManager;
  }

  get nav(): AppNav {
    return this._nav;
  }

  enterSplash(): void {
    this.flow = AppFlow.SPLASH;
  }

  enterAuth(): void {
    this.flow = AppFlow.AUTH;
  }

  enterMain(): void {
    this.flow = AppFlow.MAIN;
  }
}

const APP_STATE: AppState = new AppState();

export function useAppState(): AppState {
  return APP_STATE;
}
