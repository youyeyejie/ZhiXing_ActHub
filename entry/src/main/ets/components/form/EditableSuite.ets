import { AutoSaveText } from './AutoSaveText';
import { AppState } from '../../app/AppStates';

/**
 * 自动保存编辑套件。
 * 聚合常见输入字段并统一反馈最近一次保存状态。
 */
@ComponentV2
export struct EditableSuite {
  @Consumer('appState') appState: AppState = new AppState();
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
        .fontColor(this.appState.theme.palette.textPrimary);

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
        .fontColor(this.appState.theme.palette.textSecondary);
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.appState.theme.palette.surface);
  }
}
