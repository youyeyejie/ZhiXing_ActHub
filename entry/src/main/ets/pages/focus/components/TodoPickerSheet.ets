import { AppState, useAppState } from '../../../app/AppStates';
import { Todo } from '../../../core/models/Todo';
import { TodoRepository } from '../../../core/repositories/TodoRepository';

/**
 * 组件功能简介：
 * - 专注前待办选择器，基于ActionSheet实现。
 * - 显示未完成的待办列表，支持选择关联到专注引擎。
 *
 * 可传入项：
 * - 无（已重构为直接读取全局 AppState 中的 focusEngine）
 *
 * 返回行为：
 * - 渲染待办列表内容，交由外层 ActionSheet overlay 容器承载。
 * - 点击待办项会关联到专注引擎并关闭面板。
 *
 * 副作用：
 * - 查询数据库获取未完成待办列表。
 * - 设置全局 focusEngine.todoId 时会更新专注引擎状态。
 */
@ComponentV2
export struct TodoPickerSheet {
  @Local private app: AppState = useAppState();
  
  /** 未完成待办列表 */
  @Local private todos: Todo[] = [];
  
  /** 加载状态 */
  @Local private isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadTodos();
  }

  /** 加载未完成待办列表 */
  private async loadTodos(): Promise<void> {
    try {
      this.isLoading = true;
      const repository = new TodoRepository();
      const unfinishedTodos = await repository.getUnfinishedTodos();
      
      this.todos = unfinishedTodos;
      console.info(`[TodoPickerSheet] 加载了 ${unfinishedTodos.length} 个未完成待办`);
    } catch (error) {
      console.error('[TodoPickerSheet] 加载待办列表失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /** 处理待办项点击 */
  private onTodoItemClick(todo: Todo): void {
    try {
      const todoId = todo?.id ? String(todo.id) : '';
      if (todoId.length === 0) {
        return;
      }
      
      this.app.focusEngine.setRelatedTodo(todoId, `${todo.content || ''}`);

      const preview = `${todo.content || ''}`;
      const previewText = preview.length > 15 ? `${preview.substring(0, 15)}...` : preview;
      console.info(`[TodoPickerSheet] 已选择待办: ${previewText} (ID: ${todoId})`);

      // 通过导航栈关闭 ActionSheet overlay route
      this.app.nav.back(false);
    } catch (error) {
      console.error('[TodoPickerSheet] 处理待办项点击时发生错误:', error);
    }
  }

  /** 渲染加载状态 */
  @Builder
  private renderLoading(): void {
    Column({ space: 12 }) {
      Progress({ value: 30, total: 100, type: ProgressType.Ring })
        .width(40)
        .height(40)
        .style({ strokeWidth: 4 });
      Text('加载待办中...')
        .fontSize(14)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  /** 渲染空状态 */
  @Builder
  private renderEmpty(): void {
    Column({ space: 12 }) {
      Text('暂无待办任务')
        .fontSize(16)
        .fontColor(this.app.theme.palette.textSecondary);
      Text('请先创建待办任务')
        .fontSize(12)
        .fontColor(this.app.theme.palette.textTertiary);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  /** 渲染待办项列表 */
  @Builder
  private renderTodoList(): void {
    Scroll() {
      Column({ space: 12 }) {
        ForEach(this.todos, (todo: Todo) => {
          Column({ space: 6 }) {
            Row({ space: 12 }) {
              // 待办内容
              Column({ space: 4 }) {
                Text(todo.content)
                  .fontSize(16)
                  .fontColor(this.app.theme.palette.textPrimary)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
                
                // 创建时间（可选显示）
                if (todo.createdAt > 0) {
                  Text(`创建于: ${new Date(todo.createdAt).toLocaleDateString()}`)
                    .fontSize(12)
                    .fontColor(this.app.theme.palette.textTertiary);
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              
              // 选择箭头
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(16)
                .fontColor([this.app.theme.palette.textSecondary]);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            
            // 分隔线
            Divider()
              .color(this.app.theme.palette.border)
              .strokeWidth(0.5);
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.onTodoItemClick(todo);
          });
        }, (todo: Todo) => todo.id);
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%');
  }

  build() {
    Column({ space: 16 }) {
      // 标题栏
      Row({ space: 12 }) {
        Text('选择专注任务')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary);

        if (!this.isLoading) {
          Text(`(${this.todos.length}个待办)`)
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary);
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      // 待办列表区域 - 根据状态显示不同内容
      if (this.isLoading) {
        this.renderLoading();
      } else if (this.todos.length === 0) {
        this.renderEmpty();
      } else {
        this.renderTodoList();
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
  }
}