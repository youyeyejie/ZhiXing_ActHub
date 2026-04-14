/**
 * 组件功能简介：
 * - 专注任务选择器组件，显示当前关联的任务名称或提供“选择任务”的交互入口。
 *
 * 可传入项：
 * - @Event onOpenPicker: () => void (点击组件触发的回调，用于通知父组件打开选择器面板)
 *
 * 返回行为：
 * - 渲染一个圆角矩形的任务标签。有任务时显示书签图标和任务名（超长截断），无任务或加载中时显示相应的提示文案。
 *
 * 副作用：
 * - `aboutToAppear` 和对 `app.focusEngine.todoId` 的 `@Monitor` 监听会触发异步调用 `engine.getTodoName()`，查询并更新组件内部的待办名称缓存 (`currentTodoName`)。
 */
import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine } from '../../../core/services/FocusTimerEngine';

/**
 * 专注任务选择器组件。
 * 显示当前任务名称或提供选择任务的入口。
 * 支持点击打开待办选择器面板。
 * 组件宽度会根据任务名称长度自适应。
 */
@ComponentV2
export struct FocusTaskSelector {
  @Local private app: AppState = useAppState();
  
  /** 打开待办选择器的事件回调 */
  @Event onOpenPicker: () => void = () => {};
  
  /** 当前任务名称 */
  @Local private currentTodoName: string = '';
  
  /** 加载状态 */
  @Local private isLoading: boolean = false;

  private get engine(): FocusTimerEngine {
    return this.app.focusEngine;
  }

  aboutToAppear(): void {
    this.loadCurrentTodo();
  }

  /** 监听全局引擎中待办 ID 的变化 */
  @Monitor("app.focusEngine.todoId")
  onTodoIdChanged(): void {
    this.loadCurrentTodo(); 
  }

  /** 加载当前待办名称 */
  private async loadCurrentTodo(): Promise<void> {
    if (!this.engine.hasTodo()) {
      this.currentTodoName = '';
      return;
    }

    try {
      this.isLoading = true;
      // 优先从引擎获取名称（引擎内包含缓存逻辑）
      const todoName = await this.engine.getTodoName();
      this.currentTodoName = todoName || '';
    } catch (error) {
      console.error('[FocusTaskSelector] 获取待办名称失败:', error);
      this.currentTodoName = '';
    } finally {
      this.isLoading = false;
    }
  }

  /** 渲染任务名称内容 */
  @Builder
  private renderTodoContent(): void {
    if (this.isLoading) {
      Text('加载中...')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textTertiary)
    } else if (this.currentTodoName.length > 0) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(14)
          .fontColor([this.app.theme.palette.textSecondary]);

        Text(this.currentTodoName)
          .fontSize(16)
          .fontColor(this.app.theme.palette.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    } else {
      this.renderNoTask();
    }
  }

  /** 渲染无任务时的占位提示 */
  @Builder
  private renderNoTask(): void {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.bookmark'))
        .fontSize(14)
        .fontColor([this.app.theme.palette.textSecondary]);

      Text('选择专注任务')
        .fontSize(16)
        .fontColor(this.app.theme.palette.textSecondary);
    }
  }

  build() {
    Column() {
      if (this.engine.hasTodo()) {
        this.renderTodoContent()
      } else {
        this.renderNoTask()
      }
    }
    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
    .backgroundColor(this.app.theme.palette.surface)
    .borderRadius(10)
    .border({ width: 1, color: this.app.theme.palette.border })
    .constraintSize({
      minWidth: 150,
      maxWidth: '85%'
    })
    .onClick(() => {
      this.onOpenPicker();
    })
  }
}