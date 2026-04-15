import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoRepository } from '../../../core/repositories/TodoRepository';
import { TodoPageState, useTodoPageState } from '../../todo/TodoPageState';
import { TodoPickerStyle } from './TodoPickerStyle';

/**
 * 组件功能简介：
 * - 专注前待办选择器弹层内容，用于展示未完成的待办任务列表，并允许用户将选中的任务绑定到当前的专注计时中。
 * - 样式可由TodoPickerStyle.ets修改
 *
 * 可传入项：
 * - 无显式 @Param 传参（组件完全依赖并消费全局的 AppState 和 TodoPageState）。
 *
 * 返回行为：
 * - 渲染包含标题栏和“取消”按钮的顶部控制区。
 * - 渲染内容区：根据加载状态动态切换 Loading 态、空数据提示态，或支持滚动的待办任务卡片列表（包含当前选中项高亮和其他可选列表）。
 *
 * 副作用：
 * - 组件挂载 (aboutToAppear) 时，会触发本地数据库的异步查询，拉取未完成的待办事项数据。
 * - 点击某个待办卡片后，会直接修改全局 FocusTimerEngine 中的 relatedTodoId。
 * - 点击任务卡片或取消按钮时，会触发 app.nav.back(false) 强制销毁当前覆盖层路由。
 */
@ComponentV2
export struct TodoPickerSheet {
  @Local private app: AppState = useAppState();
  @Local private todoState: TodoPageState = useTodoPageState();
  
  @Local private todos: Todo[] = [];
  @Local private isLoading: boolean = true;
  @Local private currentTodo: Todo | undefined = undefined;

  private get availableTodos(): Todo[] {
    return this.todos.filter(t => t.id !== this.app.focusEngine.todoId);
  }

  aboutToAppear(): void {
    this.todoState.refreshTodos()
    this.loadData();
  }

  private async loadData(): Promise<void> {
    try {
      this.isLoading = true;
      const repository = new TodoRepository();
      
      this.todos = await repository.getUnfinishedTodos();
      
      if (this.app.focusEngine.hasTodo()) {
        const currentId = this.app.focusEngine.todoId;
        let matchedTodo: Todo | undefined = this.todos.find(t => t.id === currentId);
        
        if (!matchedTodo) {
          const dbResult = await repository.findById(currentId);
          matchedTodo = dbResult !== null ? dbResult : undefined;
        }
        this.currentTodo = matchedTodo;
      }
    } catch (error) {
      console.error('[TodoPickerSheet] 加载待办列表失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private onTodoItemClick(todoId: number): void {
    if (todoId <= 0) return;
    this.app.focusEngine.setRelatedTodo(todoId);
    this.app.nav.back(false);
  }

  // --- 样式解析辅助方法 ---

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    return text === "undefined" || text === "null" ? "" : text;
  }

  private resolveTodoTitle(todo: Todo): string {
    const title = this.normalizeText(todo.content);
    return title.length > 0 ? title : "未命名待办";
  }

  private resolveCategoryBorderColor(todo: Todo): string {
    return this.todoState.resolveCategoryColor(todo.categoryId);
  }

  private resolveCategoryBackgroundColor(todo: Todo): string {
    const color = this.normalizeText(this.resolveCategoryBorderColor(todo));
    if (color.length === 7 && color.charAt(0) === "#") {
      return `#1A${color.substring(1)}`;
    }
    if (color.length === 9 && color.charAt(0) === "#") {
      return `#1A${color.substring(3)}`;
    }
    return this.app.theme.palette.surfaceSecondary;
  }

  // --- UI 构建方法 ---

  @Builder
  private renderLoading(): void {
    Column({ space: TodoPickerStyle.COLUMN_SPACE_LARGE }) {
      Progress({ value: 30, total: 100, type: ProgressType.Ring })
        .width(40)
        .height(40)
        .style({ strokeWidth: 4 });
      Text('加载待办中...')
        .fontSize(TodoPickerStyle.TITLE_FONT_SIZE) // 近似原14
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private renderEmpty(): void {
    Column({ space: TodoPickerStyle.COLUMN_SPACE_LARGE }) {
      Text('暂无待办任务')
        .fontSize(TodoPickerStyle.HEADER_FONT_SIZE)
        .fontColor(this.app.theme.palette.textSecondary);
      Text('请先创建待办任务')
        .fontSize(TodoPickerStyle.INFO_FONT_SIZE)
        .fontColor(this.app.theme.palette.textTertiary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private buildTodoCard(todo: Todo, isCurrent: boolean): void {
    Row({ space: TodoPickerStyle.COLUMN_SPACE_LARGE }) {
      Column({ space: TodoPickerStyle.COLUMN_SPACE_SMALL }) {
        Text(this.resolveTodoTitle(todo))
          .fontSize(TodoPickerStyle.TITLE_FONT_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');
        
        Row({ space: TodoPickerStyle.ROW_SPACE }) {
          Column()
            .width(TodoPickerStyle.INDICATOR_DOT_SIZE)
            .height(TodoPickerStyle.INDICATOR_DOT_SIZE)
            .borderRadius(TodoPickerStyle.INDICATOR_DOT_SIZE / 2)
            .backgroundColor(this.resolveCategoryBorderColor(todo))
          
          Text(this.todoState.resolveCategoryName(todo.categoryId))
            .fontSize(TodoPickerStyle.INFO_FONT_SIZE)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .width("100%")
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      SymbolGlyph(isCurrent ? $r('sys.symbol.checkmark') : $r('sys.symbol.chevron_right'))
        .fontSize(TodoPickerStyle.ICON_SIZE)
        .fontColor([isCurrent ? this.app.theme.palette.primary : this.app.theme.palette.textTertiary]);
    }
    .width('100%')
    .padding(TodoPickerStyle.CARD_PADDING)
    .alignItems(VerticalAlign.Center)
    .border({ width: 1, color: this.resolveCategoryBorderColor(todo) })
    .borderRadius(TodoPickerStyle.CARD_BORDER_RADIUS)
    .backgroundColor(this.resolveCategoryBackgroundColor(todo))
    .onClick(() => {
      if (!isCurrent) {
        this.onTodoItemClick(todo.id);
      }
    })
  }

  @Builder
  private renderTodoList(): void {
    Scroll() {
      Column({ space: TodoPickerStyle.COLUMN_SPACE_LARGE }) {
        
        if (this.app.focusEngine.hasTodo() && this.currentTodo) {
          Text("当前选择")
            .fontSize(TodoPickerStyle.SUB_HEADER_FONT_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
            .width('100%') 

          this.buildTodoCard(this.currentTodo, true);
        }
        
        if (this.availableTodos.length > 0) {
          Text(this.app.focusEngine.hasTodo() ? "其他未完成待办" : "未完成待办")
            .fontSize(TodoPickerStyle.SUB_HEADER_FONT_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
            .width('100%') 

          ForEach(this.availableTodos, (todo: Todo) => {
            this.buildTodoCard(todo, false);
          }, (todo: Todo) => `${todo.id}`);
        }
      }
      .width('100%')
      .padding({ bottom: TodoPickerStyle.BOTTOM_PADDING }) 
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .layoutWeight(1)
  }

  build() {
    Column({ space: TodoPickerStyle.COLUMN_SPACE_LARGE }) { 
      Row() {
        Text("选择专注任务")
          .fontSize(TodoPickerStyle.HEADER_FONT_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)

        Button("取消")
          .type(ButtonType.Capsule)
          .height(40)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .fontColor(this.app.theme.palette.textSecondary)
          .onClick(() => {
            this.app.nav.back(false);
          })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      // 内容区域
      if (this.isLoading) {
        this.renderLoading();
      } else if (this.todos.length === 0 && !this.app.focusEngine.hasTodo()) {
        this.renderEmpty();
      } else {
        this.renderTodoList();
      }
    }
    .width("100%")
    .height("100%")
  }
}
