import { AppState, useAppState } from '../../../app/AppStates';
import { ActionSheet, ActionSheetController } from '../../../components/card/ActionSheet';
import { TodoCategory } from '../../../core/models/TodoCategory';
import { useTodoPageState, TodoPageState } from '../TodoPageState';
import promptAction from '@ohos.promptAction';

/**
 * 待办新建/编辑半屏页骨架。
 * TODO: 后续承载待办内容、分类和详情编辑字段。
 */
@ComponentV2
export struct TodoEditorSheet {
  @Local private app: AppState = useAppState();
  @Local private state: TodoPageState = useTodoPageState();
  private sheetController: ActionSheetController = new ActionSheetController();

  @Local private draftContent: string = '';
  @Local private draftCategoryId: string = '';

  aboutToAppear(): void {
    // 刷新由 TodoPage 统一触发，打开弹层时 open() 会再次 refreshAll 确保数据最新。
  }

  private normalizeId(value: string): string {
    return `${value}`.trim();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private async open(): Promise<void> {
    await this.state.refreshAll();
    this.draftContent = '';
    this.draftCategoryId = this.state.selectedCategoryId.length > 0 ?
      this.normalizeId(this.state.selectedCategoryId) : this.normalizeId(this.state.getDefaultCategoryId());
    if (this.draftCategoryId.length === 0 && this.state.categories.length > 0) {
      this.draftCategoryId = this.normalizeId(this.state.categories[0].id);
    }
    this.state.openCreateTodo();
  }

  private submit(): void {
    const content = this.draftContent;
    const categoryId = this.draftCategoryId;
    this.state.createTodo(content, categoryId)
      .then((ok: boolean) => {
        if (ok) {
          this.close();
          this.safeToast('待办已添加');
        } else {
          this.safeToast('添加失败：请填写内容并选择分类');
        }
      })
      .catch((_error: object) => {
        this.safeToast('添加失败：数据库异常 ' + `${_error}`);
      });
  }

  private close(): void {
    this.state.closeTodoEditor();
    this.draftContent = '';
  }

  @Builder
  private buildTagChip(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .stateEffect(true)
      .fontSize(12)
      .backgroundColor(selected ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
      .fontColor(selected ? this.app.theme.palette.surface : this.app.theme.palette.textSecondary)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        onTap();
      });
  }

  @Builder
  private buildContent() {
    Column({ space: 12 }) {
      Row() {
        Text('新增待办')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        Button('完成')
          .type(ButtonType.Capsule)
          .height(40)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .onClick(() => {
            this.submit();
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      TextInput({ text: this.draftContent, placeholder: '请输入待办内容' })
        .fontSize(14)
        .width('100%')
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.draftContent = value;
        });

      Text('分类')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Scroll() {
        Row({ space: 10 }) {
          if (this.state.categories.length === 0) {
            Text('暂无分类（默认应有“学习”），请先在上方分类区域添加')
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary);
          }
          ForEach(this.state.categories, (cat: TodoCategory) => {
            this.buildTagChip(
              cat.category,
              this.normalizeId(this.draftCategoryId) === this.normalizeId(cat.id),
              () => {
                this.draftCategoryId = this.normalizeId(cat.id);
              }
            );
          }, (cat: TodoCategory) => `${this.normalizeId(cat.id)}_${this.normalizeId(this.draftCategoryId)}`);
        }
        .padding({ top: 2, bottom: 2 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%');

      Text('提示：右滑待办可进入专注；左滑删除并支持 5 秒撤销。')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%');
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Button('+')
        .type(ButtonType.Circle)
        .width(64)
        .height(64)
        .fontSize(28)
        .fontColor(this.app.theme.palette.surface)
        .backgroundColor(this.app.theme.palette.primary)
        .shadow({ radius: 14, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 6 })
        .onClick(async () => {
          await this.open();
        });

      if (this.state.isTodoEditorVisible) {
        ActionSheet({
          isVisible: true,
          panelHeight: '55%',
          controller: this.sheetController,
          onDismiss: () => {
            this.close();
          }
        }) {
          this.buildContent();
        }
      }
    }
    .width('100%')
    .padding({ right: 18, bottom: 18 });
  }
}
