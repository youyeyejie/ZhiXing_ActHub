import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoRepository } from '../../../core/repositories/TodoRepository';
import { TodoPageState, useTodoPageState } from '../../todo/TodoPageState';
import { TodoPickerStyle } from './TodoPickerStyle';

/**
 * 组件功能简介：
 * - 专注前待办选择器，基于ActionSheet实现。
 * - 显示未完成的待办列表，支持选择关联到专注引擎。
 * - 样式在todoPickerStyle中修改。
 */
@ComponentV2
export struct TodoPickerSheet {
  @Local private app: AppState = useAppState();
  @Local private todoState: TodoPageState = useTodoPageState();
  
  @Local private todos: Todo[] = [];
  @Local private isLoading: boolean = true;
  @Local private currentTodo: Todo | undefined = undefined;

  private get availableTodos(): Todo[] {
    return this.todos.filter(t => String(t.id) !== String(this.app.focusEngine.todoId));
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
        const currentId = String(this.app.focusEngine.todoId);
        let matchedTodo: Todo | undefined = this.todos.find(t => String(t.id) === currentId);
        
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

  private onTodoItemClick(todoId: string): void {
    if (!todoId) return;
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
        this.onTodoItemClick(String(todo.id));
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
          Text(this.app.focusEngine.hasTodo() ? "其他可选待办" : "可选待办")
            .fontSize(TodoPickerStyle.SUB_HEADER_FONT_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary)
            .width('100%') 

          ForEach(this.availableTodos, (todo: Todo) => {
            this.buildTodoCard(todo, false);
          }, (todo: Todo) => todo.id);
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
          .height(40) // 按钮高度属于交互热区硬性规范，通常不放进排版Style中
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