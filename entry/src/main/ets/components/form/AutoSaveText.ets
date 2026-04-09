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
  @Param debounceMs: number = 600;
  @Param saveOnBlur: boolean = true;
  @Event onAutoSave: (value: string) => void = (_value: string) => {};

  @Local private value: string = '';
  @Local private isSaving: boolean = false;
  @Local private saveTip: string = '尚未保存';
  private debounceTimerId: number = -1;

  aboutToDisappear(): void {
    this.clearDebounceTimer();
  }

  private clearDebounceTimer(): void {
    if (this.debounceTimerId >= 0) {
      clearTimeout(this.debounceTimerId);
      this.debounceTimerId = -1;
    }
  }

  private saveNow(): void {
    this.clearDebounceTimer();
    this.isSaving = true;
    this.onAutoSave(this.value);
    this.isSaving = false;
    this.saveTip = '已自动保存';
  }

  private scheduleSave(): void {
    this.saveTip = '输入中...';
    this.clearDebounceTimer();
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
