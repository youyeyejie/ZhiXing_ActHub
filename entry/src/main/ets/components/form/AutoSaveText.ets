import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 自动保存输入组件，提供防抖保存与失焦立即保存。
 *
 * 可传入项：
 * - @Param label/placeholder: 标题与占位文本。
 * - @Param debounceMs: 防抖间隔毫秒数。
 * - @Param saveOnBlur: 失焦时是否立即保存。
 * - @Event onAutoSave: 自动保存回调，返回当前文本。
 *
 * 返回行为：
 * - 返回带标题、输入框和保存状态提示的输入区。
 *
 * 副作用：
 * - 输入与失焦事件会触发定时器调度和外部保存回调。
 */
@ComponentV2
export struct AutoSaveText {
  @Local private app: AppState = useAppState();
  @Param label: string = '自动保存输入';
  @Param placeholder: string = '请输入内容';
  @Param initialValue: string = '';
  @Param debounceMs: number = 600;
  @Param inputHeight: number = 44;
  @Param saveOnBlur: boolean = true;
  @Param saveOnChange: boolean = true;
  @Event onAutoSave: (value: string) => void = (_value: string) => {};

  @Local private value: string = '';
  @Local private isSaving: boolean = false;
  @Local private saveTip: string = '尚未保存';
  @Local private lastSavedValue: string = '';
  private debounceTimerId: number = -1;

  aboutToAppear(): void {
    this.value = this.initialValue;
    this.lastSavedValue = this.initialValue;
    this.saveTip = this.initialValue.length > 0 ? '已加载' : '尚未保存';
  }

  aboutToDisappear(): void {
    // 组件销毁前尝试落最后一次改动，避免关闭弹层导致未保存。
    this.saveNow();
  }

  private clearDebounceTimer(): void {
    if (this.debounceTimerId >= 0) {
      clearTimeout(this.debounceTimerId);
      this.debounceTimerId = -1;
    }
  }

  private normalizeForCompare(value: string): string {
    return `${value}`.trim();
  }

  private saveNow(): void {
    this.clearDebounceTimer();
    const currentValue = this.normalizeForCompare(this.value);
    const savedValue = this.normalizeForCompare(this.lastSavedValue);
    if (currentValue === savedValue) {
      this.saveTip = '无改动';
      return;
    }
    this.isSaving = true;
    this.onAutoSave(this.value);
    this.isSaving = false;
    this.lastSavedValue = this.value;
    this.saveTip = '已自动保存';
  }

  private scheduleSave(): void {
    this.saveTip = '输入中...';
    this.clearDebounceTimer();
    if (!this.saveOnChange) {
      return;
    }
    const waitMs = Math.max(120, this.debounceMs);
    this.debounceTimerId = setTimeout(() => {
      this.saveNow();
    }, waitMs);
  }

  build() {
    Column({ space: 8 }) {
      Text(this.label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      TextInput({ text: this.value, placeholder: this.placeholder })
        .fontSize(14)
        .width('100%')
        .height(this.inputHeight)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.value = value;
          this.scheduleSave();
        })
        .onBlur(() => {
          if (this.saveOnBlur) {
            this.saveNow();
          }
        });

      Text(this.isSaving ? '保存中...' : this.saveTip)
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(12)
    .borderRadius(14)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
