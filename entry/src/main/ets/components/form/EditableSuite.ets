import { AutoSaveText } from './AutoSaveText';
import { AppState, useAppState } from '../../app/AppStates';

/**
 * 组件功能简介：
 * - 自动保存编辑套件，组合多个输入项并统一保存反馈。
 *
 * 可传入项：
 * - @Param title: 套件标题。
 * - @Event onSaveField: 字段自动保存回调（field, value）。
 *
 * 返回行为：
 * - 返回包含多个 `AutoSaveText` 子组件的编辑区域。
 *
 * 副作用：
 * - 会更新最近保存字段并触发外部保存回调。
 */
@ComponentV2
export struct EditableSuite {
  @Local private app: AppState = useAppState();
  @Param title: string = 'EditableSuite';
  @Event onSaveField: (field: string, value: string) => void = (_field: string, _value: string) => {};

  @Local private lastSavedField: string = '暂无';

  private handleAutoSave(field: string, value: string): void {
    this.lastSavedField = field;
    this.onSaveField(field, value);
  }

  build() {
    Column({ space: 12 }) {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      AutoSaveText({
        label: '标题',
        placeholder: '请输入标题',
        onAutoSave: (value: string) => {
          this.handleAutoSave('title', value);
        }
      });

      AutoSaveText({
        label: '备注',
        placeholder: '请输入备注',
        debounceMs: 800,
        onAutoSave: (value: string) => {
          this.handleAutoSave('note', value);
        }
      });

      Text('最近自动保存字段: ' + this.lastSavedField)
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
