import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoRepository } from '../../../core/repositories/TodoRepository';
import { TodoPageState, useTodoPageState } from '../../todo/TodoPageState';
import { FormTypography } from '../../../components/form/FormTypography';

/**
 * 组件功能简介：
 * - 专注前待办选择器弹层内容，用于展示未完成的待办任务列表，并允许用户将选中的任务绑定到当前的专注计时中。
 *
 * 可传入项：
 * - 无显式 @Param 传参。
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
    return this.todos.filter(t => String(t.id) !== String(this.app.focusEngine.todoId));
  }

  aboutToAppear(): void {
    this.todoState.refreshTodos();
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
          const queryId: number = Number.parseInt(currentId, 10);
          const dbResult = await repository.findById(queryId);
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
    if (todoId === undefined || todoId === null || Number.isNaN(todoId)) return;
    this.app.focusEngine.setRelatedTodo(todoId);
    this.app.nav.back(false);
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    return text === "undefined" || text === "null" ? "" : text;
  }

  private resolveTodoTitle(todo: Todo): string {
    const title = this.normalizeText(todo.content);
    return title.length > 0 ? title : "未命名待办";
  }

  private resolveCategoryBorderColor(todo: Todo): string {
    const catIdNum: number = Number(todo.categoryId);
    return this.todoState.resolveCategoryColor(catIdNum);
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

  @Builder
  private renderLoading(): void {
    Column({ space: 14 }) {
      Progress({ value: 30, total: 100, type: ProgressType.Ring })
        .width(40)
        .height(40)
        .style({ strokeWidth: 4 });
      Text('加载待办中...')
        .fontSize(FormTypography.LABEL_SIZE)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  private renderEmpty(): void {
    Column({ space: 14 }) {
      Text('暂无待办任务')
        .fontSize(FormTypography.LABEL_SIZE)
        .fontColor(this.app.theme.palette.textSecondary);
      Text('请先创建待办任务')
        .fontSize(FormTypography.LABEL_SIZE)
        .fontColor(this.app.theme.palette.textTertiary);
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  private buildTodoCard(todo: Todo, isCurrent: boolean): void {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(this.resolveTodoTitle(todo))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');
        
        if (todo.categoryId !== 0) {
          Row({ space: 10 }) {
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(this.resolveCategoryBorderColor(todo))
            
            Text(this.todoState.resolveCategoryName(Number(todo.categoryId)))
              .fontSize(12)
              .fontColor(this.app.theme.palette.textSecondary)
          }
          .width("100%")
          .alignItems(VerticalAlign.Center)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      SymbolGlyph(isCurrent ? $r('sys.symbol.checkmark') : $r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([isCurrent ? this.app.theme.palette.primary : this.app.theme.palette.textTertiary]);
    }
    .width('100%')
    .padding(12)
    .alignItems(VerticalAlign.Center)
    .border({ width: 1, color: this.resolveCategoryBorderColor(todo) })
    .borderRadius(12)
    .backgroundColor(this.resolveCategoryBackgroundColor(todo))
    .onClick(() => {
      if (!isCurrent) {
        this.onTodoItemClick(Number(todo.id));
      }
    })
  }

  @Builder
  private renderTodoList(): void {
    Scroll() {
      Column({ space: 12 }) {
        if (this.app.focusEngine.hasTodo() && this.currentTodo) {
          Text("--- 当前选择 ---")
            .fontSize(FormTypography.INFO_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center);

          this.buildTodoCard(this.currentTodo, true);
        }
        
        if (this.availableTodos.length > 0) {
          Text(this.app.focusEngine.hasTodo() ? "--- 其他未完成待办 ---" : "--- 未完成待办 ---")
            .fontSize(FormTypography.INFO_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center);

          ForEach(this.availableTodos, (todo: Todo) => {
            this.buildTodoCard(todo, false);
          }, (todo: Todo) => String(todo.id));
        }
      }
      .width('100%')
      .padding({ bottom: 45 }) 
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .flexShrink(1)
    .align(Alignment.Top); 
  }

  @Builder
  private buildClearButton(): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.clean'))
        .fontSize(18)
        .fontColor([this.app.theme.palette.surface]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.primary)
      .enabled(this.app.focusEngine.hasTodo())
      .onClick(() => {
        this.app.focusEngine.setRelatedTodo(0)
        this.app.nav.back(false);
      });
  }

  build() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text("选择专注任务")
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);

        this.buildClearButton();
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        this.renderLoading();
      } else if (this.todos.length === 0 && !this.app.focusEngine.hasTodo()) {
        this.renderEmpty();
      } else {
        this.renderTodoList();
      }
    }
    .width("100%")
    .justifyContent(FlexAlign.Start)
    .constraintSize({ maxHeight: '50%' })
    .flexShrink(1);
  }
}