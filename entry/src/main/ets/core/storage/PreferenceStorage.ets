import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AppConstants } from '../../app/AppConstants';

export class PreferenceStorage {
  private static instance: PreferenceStorage = new PreferenceStorage();
  private context: common.BaseContext | undefined = undefined;
  private store: preferences.Preferences | null = null;

  static getInstance(): PreferenceStorage {
    return PreferenceStorage.instance;
  }

  initialize(context: common.BaseContext): void {
    this.context = context;
    this.store = null;
  }

  isReady(): boolean {
    return this.context !== undefined && this.context !== null;
  }

  setString(key: string, value: string): Promise<void> {
    this.setStringSync(key, value);
    return Promise.resolve();
  }

  getString(key: string, fallback: string = ''): Promise<string> {
    return Promise.resolve(this.getStringSync(key, fallback));
  }

  setBoolean(key: string, value: boolean): Promise<void> {
    this.setBooleanSync(key, value);
    return Promise.resolve();
  }

  getBoolean(key: string, fallback: boolean = false): Promise<boolean> {
    return Promise.resolve(this.getBooleanSync(key, fallback));
  }

  remove(key: string): Promise<void> {
    this.removeSync(key);
    return Promise.resolve();
  }

  setStringSync(key: string, value: string): void {
    try {
      const store = this.getStore();
      store.putSync(key, value);
      store.flushSync();
    } catch (_error) {
    }
  }

  getStringSync(key: string, fallback: string = ''): string {
    try {
      const value = this.getStore().getSync(key, fallback);
      return typeof value === 'string' ? value : fallback;
    } catch (_error) {
      return fallback;
    }
  }

  setBooleanSync(key: string, value: boolean): void {
    try {
      const store = this.getStore();
      store.putSync(key, value);
      store.flushSync();
    } catch (_error) {
    }
  }

  getBooleanSync(key: string, fallback: boolean = false): boolean {
    try {
      const value = this.getStore().getSync(key, fallback);
      return value === true;
    } catch (_error) {
      return fallback;
    }
  }

  removeSync(key: string): void {
    try {
      const store = this.getStore();
      store.deleteSync(key);
      store.flushSync();
    } catch (_error) {
    }
  }

  private getStore(): preferences.Preferences {
    const context: common.BaseContext | undefined = this.context;
    if (context === undefined) {
      throw new Error('PreferenceStorage has not been initialized.');
    }

    if (this.store !== null) {
      return this.store;
    }

    this.store = preferences.getPreferencesSync(context, {
      name: AppConstants.PREFERENCE_NAME,
    });
    return this.store;
  }
}
