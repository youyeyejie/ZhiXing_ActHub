import { AppState, useAppState } from '../../../app/AppStates';
import { FocusTimerEngine } from '../../../core/services/FocusTimerEngine';
import { Todo } from '../../../core/models/Todo';
import { TodoRepository } from '../../../core/repositories/TodoRepository';
import { ActionSheet, ActionSheetController } from '../../../components/card/ActionSheet';

/**
 * 组件功能简介：
 * - 专注前待办选择器，基于ActionSheet实现。
 * - 显示未完成的待办列表，支持选择关联到专注引擎。
 *
 * 可传入项：
 * - @Param engine: FocusTimerEngine - 专注引擎，用于设置关联待办ID
 * - @Param controller: ActionSheetController - ActionSheet控制器，用于控制面板显示/隐藏
 *
 * 返回行为：
 * - 渲染半屏弹层，包含未完成待办列表。
 * - 点击待办项会关联到专注引擎并关闭面板。
 *
 * 副作用：
 * - 查询数据库获取未完成待办列表。
 * - 设置engine.todoId时会更新专注引擎状态。
 */
@ComponentV2
export struct TodoPickerSheet {
  @Local private app: AppState = useAppState();
  
  /** 外部传入的专注引擎 */
  @Require @Param engine: FocusTimerEngine;
  
  /** 外部传入的ActionSheet控制器 */
  @Require @Param controller: ActionSheetController;
  
  /** 关闭回调（当ActionSheet通过遮罩层关闭时调用） */
  @Event onClose: () => void = () => {};

  /** 未完成待办列表 */
  @Local private todos: Todo[] = [];
  
  /** 加载状态 */
  @Local private isLoading: boolean = true;

  aboutToAppear(): void {
    console.log('TodoPickerSheet aboutToAppear');
    console.log('控制器状态:', this.controller ? '有效' : 'undefined');
    console.log('控制器dismiss:', typeof this.controller?.dismiss);
    
    this.loadTodos();
  }

  /** 加载未完成待办列表 */
  private async loadTodos(): Promise<void> {
    try {
      this.isLoading = true;
      const repository = new TodoRepository();
      const unfinishedTodos = await repository.getUnfinishedTodos();
      
      // 诊断日志：检查待办ID类型
      console.log(`加载了${unfinishedTodos.length}个未完成待办`);
      unfinishedTodos.forEach((todo, index) => {
        console.log(`待办${index + 1}: id="${todo.id}", 类型=${typeof todo.id}, 内容="${todo.content.substring(0, 30)}..."`);
      });
      
      this.todos = unfinishedTodos;
    } catch (error) {
      console.error('加载待办列表失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /** 处理待办项点击 */
  private onTodoItemClick(todo: Todo): void {
    try {
      console.log('开始处理待办项点击，待办ID:', todo?.id);
      console.log('ID类型:', typeof todo?.id);
      console.log('引擎状态:', this.engine ? '有效' : 'undefined');
      console.log('控制器状态:', this.controller ? '有效' : 'undefined');
      console.log('控制器dismiss类型:', typeof this.controller?.dismiss);
      
      // 设置专注引擎关联的待办ID - 确保转换为字符串，使用封装方法
      const todoId = todo?.id ? String(todo.id) : '';
      this.engine.setRelatedTodo(todoId);
      console.log(`已选择待办: ${todo.content.substring(0, 20)}... (ID: ${todoId.substring(0, 8)})`);
      
      // 关闭ActionSheet面板 - 添加防御性检查
      if (typeof this.controller.dismiss === 'function') {
        console.log('通过controller.dismiss关闭ActionSheet');
        this.controller.dismiss();
      } else {
        console.warn('controller.dismiss未定义，通过onClose事件关闭');
        // 直接触发关闭事件，让父组件处理关闭逻辑
        this.onClose();
      }
      
      console.log('待办项点击处理完成');
    } catch (error) {
      console.error('处理待办项点击时发生错误:', error);
      console.error('错误堆栈:', error?.stack);
      
      // 尝试通过onClose事件安全关闭
      try {
        this.onClose();
      } catch (closeError) {
        console.error('调用onClose也失败:', closeError);
      }
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
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%');
  }

  build() {
    // 使用ActionSheet作为容器
    ActionSheet({
      controller: this.controller,
      panelHeight: '60%',
      keyboardOffset: 0,
      onDismiss: () => {
        console.log('TodoPickerSheet已关闭');
        // 通知父组件关闭事件
        this.onClose();
      }
    }) {
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
    }
  }
}
