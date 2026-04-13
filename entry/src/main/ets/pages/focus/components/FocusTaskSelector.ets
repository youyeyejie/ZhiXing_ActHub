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
  @Require @Param engine: FocusTimerEngine;
  
  /** 打开待办选择器的事件回调 */
  @Event onOpenPicker: () => void = () => {};
  
  /** 当前任务名称 */
  @Local private currentTodoName: string = '';
  
  /** 加载状态 */
  @Local private isLoading: boolean = false;

  /** 组件加载时检查是否有待办并加载内容 */
  aboutToAppear(): void {
    console.log(`FocusTaskSelector.aboutToAppear: todoId=${this.engine.todoId}`);
    this.loadCurrentTodo();
  }

  /** 监听引擎todoId变化 */
  @Monitor("engine.todoId")
  onTodoIdChanged(): void {
    console.log(`监测到引擎 todoId 变为: ${this.engine.todoId}`);
    this.loadCurrentTodo(); 
  }

  /** 监听引擎todoTitle变化 */
  @Monitor("engine.todoTitle")
  onTodoTitleChanged(): void {
    this.loadCurrentTodo();
  }

  /** 加载当前待办名称 */
  private async loadCurrentTodo(): Promise<void> {
    if (!this.engine.hasTodo()) {
      this.currentTodoName = '';
      return;
    }

    if (`${this.engine.todoTitle}`.trim().length > 0) {
      this.currentTodoName = `${this.engine.todoTitle}`.trim();
      return;
    }

    try {
      this.isLoading = true;
      console.log('FocusTaskSelector: 开始从引擎获取待办名称...');
      const todoName = await this.engine.getTodoName();
      this.currentTodoName = todoName || '';
      console.log(`FocusTaskSelector: 获取到待办名称: "${todoName}"`);
    } catch (error) {
      console.error('从引擎获取待办名称失败:', error);
      this.currentTodoName = '';
    } finally {
      this.isLoading = false;
    }
  }

  /** 渲染任务名称显示 */
  @Builder
  private renderTodoContent(): void {
    if (this.isLoading) {
      // 加载中状态
      Text('加载中...')
        .fontSize(16)
        .fontColor(this.app.theme.palette.textSecondary)
        .textAlign(TextAlign.Center)
    } else if (this.currentTodoName.length > 0) {
      // 显示任务名称
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(14)
          .fontColor([this.app.theme.palette.textSecondary]);

        Text(this.currentTodoName)
          .fontSize(16)
          .fontColor(this.app.theme.palette.textPrimary)
          .textAlign(TextAlign.Start)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    } else {
      // 无任务时显示提示
      this.renderNoTask();
    }
  }

  /** 渲染无任务提示 */
  @Builder
  private renderNoTask(): void {
    Row({ space: 8 }) {
      Text(){
        SymbolSpan($r('sys.symbol.bookmark'))
          .fontWeight(FontWeight.Normal)
          .fontSize(14)
          .fontColor([this.app.theme.palette.textSecondary])
      }
      Text('选择专注任务')
        .fontSize(16)
        .fontColor(this.app.theme.palette.textSecondary)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    // 容器：根据内容自适应宽度
    Column({ space: 8 }) {
      if (this.engine.hasTodo()) {
        // 有关联待办时显示任务名称
        this.renderTodoContent()
      } else {
        // 无关联待办时显示提示
        this.renderNoTask()
      }
    }
    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
    .backgroundColor(this.app.theme.palette.surface) // 使用surface背景色
    .borderRadius(10)
    .border({ width: 1, color: this.app.theme.palette.border }) // 细边框
    .constraintSize({
      minWidth: 150,
      maxWidth: '80%'
    })
    .onClick(() => {
      // 点击任务区域打开待办选择器
      console.log('打开待办选择器');
      this.onOpenPicker();
    })
  }
}
