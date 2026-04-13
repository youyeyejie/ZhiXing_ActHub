import { Todo } from '../main/ets/core/models/Todo';
import { TodoRepository } from '../main/ets/core/repositories/TodoRepository';

/**
 * 测试数据助手：专注模块测试待办数据生成器
 * 
 * 类功能简介：
 * - 提供测试用待办数据的生成和插入功能
 * - 支持创建已完成和未完成的待办任务
 * - 提供便捷的测试数据清理方法
 * 
 * 使用场景：
 * 1. 开发阶段快速生成测试数据
 * 2. 专注模块UI测试和功能验证
 * 3. TodoPickerSheet组件的可视化测试
 * 
 * 注意事项：
 * - 仅限开发测试使用，生产环境应禁用
 * - 调用前需确保数据库已初始化
 */
export class TodoTestDataHelper {
  private repository: TodoRepository = new TodoRepository();

  /**
   * 生成并插入测试待办数据
   * @param count 生成数量（默认5个）
   * @returns Promise<number> 成功插入的数量
   */
  async insertTestTodos(count: number = 5): Promise<number> {
    try {
      console.log(`开始生成${count}个测试待办数据...`);
      
      const todos = this.generateTestTodos(count);
      let insertedCount = 0;
      
      for (const todo of todos) {
        try {
          await this.repository.save(todo);
          insertedCount++;
          console.log(`已插入待办: ${todo.content.substring(0, 20)}... (ID: ${todo.id.substring(0, 8)})`);
        } catch (error) {
          console.error(`插入待办失败: ${todo.content.substring(0, 20)}...`, error);
        }
      }
      
      console.log(`测试数据生成完成，共插入${insertedCount}个待办`);
      return insertedCount;
      
    } catch (error) {
      console.error('生成测试待办数据失败:', error);
      return 0;
    }
  }

  /**
   * 生成测试待办数据（包含已完成和未完成）
   * @param count 总数量
   * @returns Todo[] 待办数组
   */
  private generateTestTodos(count: number): Todo[] {
    const now = Date.now();
    const oneDayMs = 24 * 60 * 60 * 1000;
    
    const testTodos: Todo[] = [
      // 未完成待办（用于专注选择）
      this.createTodo('1', '完成课程论文初稿', now - 2 * oneDayMs, 0),
      this.createTodo('2', '学习ArkTS组件开发', now - 1 * oneDayMs, 0),
      this.createTodo('3', '准备项目演示文稿', now - 3 * oneDayMs, 0),
      this.createTodo('4', '复习数据库设计原理', now - 4 * oneDayMs, 0),
      this.createTodo('5', '练习HarmonyOS UI动画', now - 0.5 * oneDayMs, 0),
      
      // 已完成待办（不应在Picker中显示）
      this.createTodo('6', '提交期中作业', now - 5 * oneDayMs, 1),
      this.createTodo('7', '完成小组项目会议', now - 6 * oneDayMs, 1),
      
      // 长期任务
      this.createTodo('8', '每日英语学习打卡', now - 7 * oneDayMs, 0),
      this.createTodo('9', '每周健身计划执行', now - 8 * oneDayMs, 0),
      this.createTodo('10', '月度技术文章总结', now - 9 * oneDayMs, 0),
    ];
    
    // 如果请求数量超过已有数据，生成更多
    if (count > testTodos.length) {
      for (let i = testTodos.length + 1; i <= count; i++) {
        const isDone = i % 3 === 0 ? 1 : 0; // 每3个中1个已完成
        const daysAgo = Math.floor(Math.random() * 10);
        const content = `测试待办任务 #${i} - ${isDone === 0 ? '未完成' : '已完成'}`;
        testTodos.push(this.createTodo(`${i}`, content, now - daysAgo * oneDayMs, isDone));
      }
    }
    
    // 返回指定数量的待办
    return testTodos.slice(0, count);
  }

  /**
   * 创建单个待办对象
   */
  private createTodo(id: string, content: string, createdAt: number, isDone: number): Todo {
    const todo = new Todo();
    todo.id = `test_todo_${id}_${Date.now()}`;
    todo.content = content;
    todo.timestamp = createdAt;
    todo.categoryId = '';
    todo.isDone = isDone;
    todo.inFocus = 0;
    todo.createdAt = createdAt;
    todo.updatedAt = createdAt;
    return todo;
  }

  /**
   * 清除所有测试待办数据
   * @returns Promise<number> 删除的数量
   */
  async clearTestTodos(): Promise<number> {
    try {
      const allTodos = await this.repository.findAll();  
      let deletedCount = 0;    
      for (const todo of allTodos) {
        try {
          await this.repository.removeById(todo.id);
          deletedCount++;
          console.log(`已删除测试待办: ${todo.content.substring(0, 20)}... (ID: ${todo.id.substring(0, 8)})`);
        } catch (error) {
          console.error(`删除测试待办失败: ${todo.id}`, error);
        }
      }
      
      console.log(`清理完成，共删除${deletedCount}个测试待办`);
      return deletedCount;
    } catch (error) {
      console.error('清理测试待办失败:', error);
      return 0;
    }
  }

  /**
   * 获取当前未完成待办数量（用于验证）
   * @returns Promise<number> 未完成待办数量
   */
  async getUnfinishedTodoCount(): Promise<number> {
    try {
      const todos = await this.repository.getUnfinishedTodos();
      return todos.length;
    } catch (error) {
      console.error('获取未完成待办数量失败:', error);
      return 0;
    }
  }

  /**
   * 打印待办统计信息
   */
  async printTodoStats(): Promise<void> {
    try {
      const allTodos = await this.repository.findAll();
      const unfinished = allTodos.filter(todo => todo.isDone === 0);
      const finished = allTodos.filter(todo => todo.isDone === 1);
      const testTodos = allTodos.filter(todo => todo.id.startsWith('test_todo_'));
      
      console.log('=== 待办统计信息 ===');
      console.log(`总待办数: ${allTodos.length}`);
      console.log(`未完成待办: ${unfinished.length}`);
      console.log(`已完成待办: ${finished.length}`);
      console.log(`测试待办: ${testTodos.length}`);
      console.log('===================');
      
      // 打印最近5个未完成待办
      if (unfinished.length > 0) {
        console.log('最近未完成待办:');
        unfinished.slice(0, 5).forEach((todo, index) => {
          const date = new Date(todo.createdAt).toLocaleDateString();
          console.log(`  ${index + 1}. ${todo.content} (${date})`);
        });
      }
    } catch (error) {
      console.error('打印待办统计失败:', error);
    }
  }

  /**
   * 快速生成专注测试数据（专注模块专用）
   * 生成5个未完成待办，适合TodoPickerSheet测试
   */
  async generateFocusTestData(): Promise<boolean> {
    console.log('开始生成专注模块测试数据...');
    
    // 先清除旧的测试数据（可选）
    await this.clearTestTodos();
    
    // 生成5个未完成待办
    const count = 5;
    const inserted = await this.insertTestTodos(count);
    
    if (inserted > 0) {
      await this.printTodoStats();
      console.log('专注模块测试数据生成完成 ✅');
      return true;
    } else {
      console.error('专注模块测试数据生成失败 ❌');
      return false;
    }
  }
}