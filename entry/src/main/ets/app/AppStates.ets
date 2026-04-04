import { ThemeManager } from '../core/theme/ThemeManager';
import { AppNav } from './AppNav';

@ObservedV2
export class AppState {
  private themeManager: ThemeManager = new ThemeManager();
  private _nav: AppNav = new AppNav();

  get theme(): ThemeManager {
    return this.themeManager;
  }

  get nav(): AppNav {
    return this._nav;
  }
}
