import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../app/AppStates';
import { FloatingActionButton } from '../../components/buttons/FloatingActionButton';
import { InteractableCard } from '../../components/card/InteractableCard';
import { UndoNotificationStack, UndoStackItem } from '../../components/feedback/UndoNotificationStack';
import { SafeAreaUtils } from '../../core/theme/SafeAreaUtils';
import { Plan } from '../../core/models/Plan';
import { TodoCategory } from '../../core/models/TodoCategory';
import { Todo } from '../../core/models/Todo';
import { Idea } from '../../core/models/Idea';
import { Focus } from '../../core/models/Focus';
import { PlanRepository } from '../../core/repositories/PlanRepository';
import { TodoCategoryRepository } from '../../core/repositories/TodoCategoryRepository';
import { TodoRepository } from '../../core/repositories/TodoRepository';
import { IdeaRepository } from '../../core/repositories/IdeaRepository';
import { FocusRepository } from '../../core/repositories/FocusRepository';

/**
 * 组件功能简介：
 * - 共享交互测试卡片数据结构，定义测试卡片的展示文本。
 *
 * 可传入项：
 * - 构造参数包含 `id`、`title`、`subtitle`。
 *
 * 返回行为：
 * - 创建用于交互测试列表的数据项。
 *
 * 副作用：
 * - 无。
 */
class DemoInteractableItem {
  id: string;
  title: string;
  subtitle: string;

  constructor(id: string, title: string, subtitle: string) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
  }
}

/**
 * 组件功能简介：
 * - 测试页撤销删除任务结构，保存回滚所需上下文。
 *
 * 可传入项：
 * - 构造参数包含任务 ID、删除项快照与原始索引。
 *
 * 返回行为：
 * - 创建撤销任务实例用于栈式管理。
 *
 * 副作用：
 * - 无。
 */
class UndoDeleteTask {
  taskId: string;
  item: DemoInteractableItem | null;
  originalIndex: number;

  constructor(taskId: string, item: DemoInteractableItem | null, originalIndex: number) {
    this.taskId = taskId;
    this.item = item;
    this.originalIndex = originalIndex;
  }
}

/**
 * 组件功能简介：
 * - 共享交互测试页面，用于验证卡片手势、撤销通知与测试数据构造流程。
 *
 * 可传入项：
 * - `onRequestDismiss`：请求关闭测试页时的回调。
 *
 * 返回行为：
 * - 渲染测试入口、日志与交互示例区域。
 *
 * 副作用：
 * - 会写入测试数据、触发仓储操作并弹出提示。
 */
@ComponentV2
export struct SharedInteractionTestPage {
  @Local private app: AppState = useAppState();
  @Param onRequestDismiss: () => void = () => {};

  @Local private logs: Array<string> = [];
  @Local private sampleCards: Array<DemoInteractableItem> = [
    new DemoInteractableItem('test_card_1', '交互卡片#1', '左滑会触发删除并生成撤销通知'),
    new DemoInteractableItem('test_card_2', '交互卡片#2', '点击卡片会打开 DetailCard'),
    new DemoInteractableItem('test_card_3', '交互卡片#3', '用于验证 InteractableCard 动作回调'),
  ];
  @Local private undoTasks: Array<UndoDeleteTask> = [];
  @Local private undoStackItems: Array<UndoStackItem> = [];
  @Local private undoSeq: number = 0;
  @Local private buildingData: boolean = false;
  @Local private testCategories: Array<TodoCategory> = [];

  private readonly HOUR_MS: number = 60 * 60 * 1000;
  private readonly DAY_MS: number = 24 * this.HOUR_MS;
  private readonly TEST_CATEGORY_LIMIT: number = 4;
  private readonly CATEGORY_TOTAL_CAPACITY: number = 8;

  private readonly planPrefix: string = '测试日程';
  private readonly categoryPrefix: string = '分类';
  private readonly todoPrefix: string = '测试待办';
  private readonly ideaPrefix: string = '测试闪记';

  private readonly ideaSamples: Array<string> = [
    '“讲完之后就去下一个片场讲。”莉雅嘴角微微翘着，“然后再去下一个世界，再再下一个世界，直到我无限的世界里到处都是你和你的故事，直到我忘掉所有过去，直到我只记得你，当无限的世界里只有你和我，我想问题应该也就能顺利解决了。”',
    '“我们分手的那天是愚人节，所以我一直当她是开玩笑，我愿意让她这个玩笑维持一个月。从分手的那一天开始，我每天买一罐5月1号到期的凤梨罐头，因为凤梨是阿May最爱吃的东西，而5月1号是我的生日。我告诉我自己，当我买满30罐的时候，她如果还不回来，这段感情就会过期。”',
    '后来才明白，我自知生命短暂，于是我驻足，享受无法复刻的瞬间',
    '偏我来时不逢春，恰我离时春满园。',
    '人长了嘴，就要把误会说清楚。生了耳，就要听旁人辩白。不要因为矫情，又或者害怕面对而逃避问题，来回扯皮，浪费光阴。',
    '辽阔的土地，生不出狭隘的爱。',
  ];

  private readonly focusMinutePattern: Array<number> = [1, 1, 4, 5, 1, 4];

  private planRepository: PlanRepository = new PlanRepository();
  private todoCategoryRepository: TodoCategoryRepository = new TodoCategoryRepository();
  private todoRepository: TodoRepository = new TodoRepository();
  private ideaRepository: IdeaRepository = new IdeaRepository();
  private focusRepository: FocusRepository = new FocusRepository();

  aboutToAppear(): void {
    this.refreshTestCategories();
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {
    }
  }

  private pushLog(message: string): void {
    const now: Date = new Date();
    const hour: string = String(now.getHours()).padStart(2, '0');
    const minute: string = String(now.getMinutes()).padStart(2, '0');
    const second: string = String(now.getSeconds()).padStart(2, '0');
    const nextLine: string = `[${hour}:${minute}:${second}] ${message}`;
    const nextLogs: Array<string> = [nextLine, ...this.logs];
    this.logs = nextLogs.slice(0, 40);
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private parseNameIndex(value: string, prefix: string): number {
    const normalized = this.normalizeText(value);
    const expectedPrefix = `${prefix}#`;
    if (!normalized.startsWith(expectedPrefix)) {
      return 0;
    }
    const suffix = normalized.substring(expectedPrefix.length);
    if (suffix.length <= 0) {
      return 0;
    }
    const parsed = Number(suffix);
    if (Number.isNaN(parsed) || parsed <= 0) {
      return 0;
    }
    return Math.floor(parsed);
  }

  private resolveNextIndex(values: Array<string>, prefix: string): number {
    let maxIndex = 0;
    for (let index = 0; index < values.length; index++) {
      maxIndex = Math.max(maxIndex, this.parseNameIndex(values[index], prefix));
    }
    return maxIndex + 1;
  }

  private resolveTodayStart(): number {
    return this.resolveDayStart(Date.now());
  }

  private resolveDayStart(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  private resolveWeekStart(todayStart: number): number {
    const date = new Date(todayStart);
    const weekDay = date.getDay();
    const offset = weekDay === 0 ? 6 : weekDay - 1;
    return todayStart - offset * this.DAY_MS;
  }

  private resolveCurrentWeekDays(): Array<number> {
    const result: Array<number> = [];
    const weekStart = this.resolveWeekStart(this.resolveTodayStart());
    for (let index = 0; index < 7; index++) {
      result.push(weekStart + index * this.DAY_MS);
    }
    return result;
  }

  private isSameDay(dayA: number, dayB: number): boolean {
    return this.resolveDayStart(dayA) === this.resolveDayStart(dayB);
  }

  private async runBuildAction(
    actionName: string,
    task: () => Promise<number>,
    successMessage: string,
  ): Promise<void> {
    if (this.buildingData) {
      this.safeToast('请等待当前任务完成');
      return;
    }
    this.buildingData = true;
    try {
      const count = await task();
      this.pushLog(`${actionName}完成，新增 ${count} 条`);
      this.safeToast(successMessage.replace('{count}', `${count}`));
    } catch (_error) {
      this.pushLog(`${actionName}失败`);
      this.safeToast(`${actionName}失败，请重试`);
    } finally {
      this.buildingData = false;
      await this.refreshTestCategories();
    }
  }

  private enqueueUndoTask(
    message: string,
    item: DemoInteractableItem | null,
    originalIndex: number,
  ): void {
    const taskId = `shared_undo_${this.undoSeq}`;
    this.undoSeq = this.undoSeq + 1;
    const stackItem = new UndoStackItem(taskId, message, '撤销', 4500);
    this.undoTasks = [...this.undoTasks, new UndoDeleteTask(taskId, item, originalIndex)];
    this.undoStackItems = [...this.undoStackItems, stackItem];
  }

  private removeUndoTask(taskId: string): void {
    this.undoTasks = this.undoTasks.filter((task: UndoDeleteTask) => task.taskId !== taskId);
    this.undoStackItems = this.undoStackItems.filter((task: UndoStackItem) => task.taskId !== taskId);
  }

  private findUndoTask(taskId: string): UndoDeleteTask | null {
    for (let index = 0; index < this.undoTasks.length; index++) {
      if (this.undoTasks[index].taskId === taskId) {
        return this.undoTasks[index];
      }
    }
    return null;
  }

  private removeCard(cardId: string): void {
    let foundIndex = -1;
    for (let index = 0; index < this.sampleCards.length; index++) {
      if (this.sampleCards[index].id === cardId) {
        foundIndex = index;
        break;
      }
    }
    if (foundIndex < 0) {
      return;
    }

    const removed = this.sampleCards[foundIndex];
    this.sampleCards = this.sampleCards.filter((item: DemoInteractableItem) => item.id !== cardId);
    this.enqueueUndoTask(`${removed.title} 已删除`, removed, foundIndex);
    this.pushLog(`${removed.title} 左滑删除，已加入撤销栈`);
    this.safeToast(`${removed.title} 左滑已触发`);
  }

  private restoreCard(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null || task.item === null) {
      this.removeUndoTask(taskId);
      this.pushLog('已撤销测试通知');
      return;
    }

    const insertIndex = Math.max(0, Math.min(task.originalIndex, this.sampleCards.length));
    const before = this.sampleCards.slice(0, insertIndex);
    const after = this.sampleCards.slice(insertIndex);
    this.sampleCards = [...before, task.item, ...after];
    this.removeUndoTask(taskId);
    this.pushLog(`${task.item.title} 已撤销恢复`);
  }

  private openActionSheetTest(): void {
    this.app.nav.openActionSheet(() => {
      this.buildActionSheetContent();
    }, 'auto');
    this.pushLog('ActionSheet 已打开');
  }

  private openDetailCardTest(): void {
    this.app.nav.openDetailCard(() => {
      this.buildDetailCardContent();
    }, '60%');
    this.pushLog('DetailCard 已打开');
  }

  private getCategoryColorPalette(): Array<string> {
    return [
      this.app.theme.palette.accentBlue,
      this.app.theme.palette.accentViolet,
      this.app.theme.palette.accentGreen,
      this.app.theme.palette.accentAmber,
    ];
  }

  private collectPlanNames(plans: Array<Plan>): Array<string> {
    const values: Array<string> = [];
    for (let index = 0; index < plans.length; index++) {
      values.push(this.normalizeText(plans[index].content));
    }
    return values;
  }

  private collectCategoryNames(categories: Array<TodoCategory>): Array<string> {
    const values: Array<string> = [];
    for (let index = 0; index < categories.length; index++) {
      values.push(this.normalizeText(categories[index].category));
    }
    return values;
  }

  private collectTodoNames(todos: Array<Todo>): Array<string> {
    const values: Array<string> = [];
    for (let index = 0; index < todos.length; index++) {
      values.push(this.normalizeText(todos[index].content));
    }
    return values;
  }

  private collectIdeaTitles(ideas: Array<Idea>): Array<string> {
    const values: Array<string> = [];
    for (let index = 0; index < ideas.length; index++) {
      values.push(this.normalizeText(ideas[index].title));
    }
    return values;
  }

  private filterTestCategories(categories: Array<TodoCategory>): Array<TodoCategory> {
    const result: Array<TodoCategory> = [];
    for (let index = 0; index < categories.length; index++) {
      const categoryName = this.normalizeText(categories[index].category);
      if (categoryName.startsWith(`${this.categoryPrefix}#`)) {
        result.push(categories[index]);
      }
    }
    result.sort((a: TodoCategory, b: TodoCategory) => {
      const aIndex = this.parseNameIndex(a.category, this.categoryPrefix);
      const bIndex = this.parseNameIndex(b.category, this.categoryPrefix);
      return aIndex - bIndex;
    });
    return result;
  }

  private async refreshTestCategories(): Promise<void> {
    try {
      const categories = await this.todoCategoryRepository.findAll();
      this.testCategories = this.filterTestCategories(categories);
    } catch (_error) {
      this.testCategories = [];
    }
  }

  private hasRequiredTestCategories(): boolean {
    return this.testCategories.length >= this.TEST_CATEGORY_LIMIT;
  }

  private async buildPlanData(): Promise<number> {
    const existingPlans = await this.planRepository.findAll();
    let nextIndex = this.resolveNextIndex(this.collectPlanNames(existingPlans), this.planPrefix);
    const weekDays = this.resolveCurrentWeekDays();
    const todayStart = this.resolveTodayStart();
    const now = Date.now();
    let insertedCount = 0;

    for (let dayIndex = 0; dayIndex < weekDays.length; dayIndex++) {
      const currentDay = weekDays[dayIndex];
      const firstPlan = new Plan();
      firstPlan.content = `${this.planPrefix}#${nextIndex}`;
      nextIndex = nextIndex + 1;
      firstPlan.startTime = currentDay + 8 * this.HOUR_MS;
      firstPlan.endTime = currentDay + 10 * this.HOUR_MS;
      firstPlan.duration = firstPlan.endTime - firstPlan.startTime;
      firstPlan.timestamp = firstPlan.startTime;
      firstPlan.location = '共享测试页构建';
      firstPlan.isCourse = 0;
      firstPlan.description = '测试数据：8:00-10:00';
      firstPlan.createdAt = now;
      firstPlan.updatedAt = now;
      await this.planRepository.save(firstPlan);
      insertedCount = insertedCount + 1;

      const secondPlan = new Plan();
      secondPlan.content = `${this.planPrefix}#${nextIndex}`;
      nextIndex = nextIndex + 1;
      secondPlan.startTime = currentDay + 14 * this.HOUR_MS;
      secondPlan.endTime = currentDay + 16 * this.HOUR_MS;
      secondPlan.duration = secondPlan.endTime - secondPlan.startTime;
      secondPlan.timestamp = secondPlan.startTime;
      secondPlan.location = '共享测试页构建';
      secondPlan.isCourse = 0;
      secondPlan.description = '测试数据：14:00-16:00';
      secondPlan.createdAt = now;
      secondPlan.updatedAt = now;
      await this.planRepository.save(secondPlan);
      insertedCount = insertedCount + 1;

      if (this.isSameDay(currentDay, todayStart)) {
        const extraPlan = new Plan();
        extraPlan.content = `${this.planPrefix}#${nextIndex}`;
        nextIndex = nextIndex + 1;
        extraPlan.startTime = now + 15 * 60 * 1000;
        extraPlan.endTime = now + 60 * 60 * 1000;
        extraPlan.duration = extraPlan.endTime - extraPlan.startTime;
        extraPlan.timestamp = extraPlan.startTime;
        extraPlan.location = '共享测试页构建';
        extraPlan.isCourse = 1;
        extraPlan.description = '测试数据：当前15min后课程';
        extraPlan.createdAt = now;
        extraPlan.updatedAt = now;
        await this.planRepository.save(extraPlan);
        insertedCount = insertedCount + 1;
      }
    }

    return insertedCount;
  }

  private async buildTodoCategoryData(): Promise<number> {
    const allCategories = await this.todoCategoryRepository.findAll();
    if (allCategories.length >= this.CATEGORY_TOTAL_CAPACITY) {
      this.safeToast(`分类数量已满（最多 ${this.CATEGORY_TOTAL_CAPACITY} 个）`);
      this.pushLog('分类数量已满，跳过创建');
      return 0;
    }

    const existingTestCategories = this.filterTestCategories(allCategories);
    if (existingTestCategories.length >= this.TEST_CATEGORY_LIMIT) {
      this.safeToast('测试分类已满');
      this.pushLog('测试分类已满，跳过创建');
      return 0;
    }

    const colors = this.getCategoryColorPalette();
    let nextIndex = this.resolveNextIndex(this.collectCategoryNames(allCategories), this.categoryPrefix);
    const now = Date.now();
    let insertedCount = 0;

    for (let index = existingTestCategories.length; index < this.TEST_CATEGORY_LIMIT; index++) {
      if (allCategories.length + insertedCount >= this.CATEGORY_TOTAL_CAPACITY) {
        break;
      }
      const category = new TodoCategory();
      category.category = `${this.categoryPrefix}#${nextIndex}`;
      nextIndex = nextIndex + 1;
      category.color = colors[index % colors.length];
      category.createdAt = now;
      category.updatedAt = now;
      await this.todoCategoryRepository.save(category);
      insertedCount = insertedCount + 1;
    }

    if (insertedCount <= 0) {
      this.safeToast('测试分类已满');
    }

    return insertedCount;
  }

  private async buildTodoData(): Promise<number> {
    await this.refreshTestCategories();
    if (!this.hasRequiredTestCategories()) {
      this.safeToast('请先创建四个测试分类');
      this.pushLog('创建待办被拦截：测试分类不足 4 个');
      return 0;
    }

    const allTodos = await this.todoRepository.findAll();
    let nextIndex = this.resolveNextIndex(this.collectTodoNames(allTodos), this.todoPrefix);
    const now = Date.now();
    let insertedCount = 0;

    for (let index = 0; index < 10; index++) {
      const todo = new Todo();
      todo.content = `${this.todoPrefix}#${nextIndex}`;
      nextIndex = nextIndex + 1;
      todo.detail = '共享测试页构建的待办数据';
      todo.timestamp = now + index * 60 * 1000;
      todo.createdAt = now;
      todo.updatedAt = now;
      todo.inFocus = 0;

      if (index < 8) {
        const categoryIndex = Math.floor(index / 2);
        todo.categoryId = this.testCategories[categoryIndex].id;
      } else {
        todo.categoryId = 0;
      }

      if (index === 0 || index === 2) {
        todo.isDone = 1;
      } else {
        todo.isDone = 0;
      }

      await this.todoRepository.save(todo);
      insertedCount = insertedCount + 1;
    }

    return insertedCount;
  }

  private sampleIdeaContent(seed: number): string {
    if (this.ideaSamples.length <= 0) {
      return '测试闪记内容';
    }
    const safeSeed = seed >= 0 ? seed : 0;
    return this.ideaSamples[safeSeed % this.ideaSamples.length];
  }

  private async buildIdeaData(): Promise<number> {
    const existingIdeas = await this.ideaRepository.findAll();
    let nextIndex = this.resolveNextIndex(this.collectIdeaTitles(existingIdeas), this.ideaPrefix);
    const todayStart = this.resolveTodayStart();
    let insertedCount = 0;

    for (let dayOffset = 30; dayOffset >= 1; dayOffset--) {
      const idea = new Idea();
      const content = this.sampleIdeaContent(nextIndex - 1);
      const timestamp = todayStart - dayOffset * this.DAY_MS + 9 * this.HOUR_MS;
      idea.title = `${this.ideaPrefix}#${nextIndex}`;
      nextIndex = nextIndex + 1;
      idea.content = content;
      idea.length = content.length;
      idea.timestamp = timestamp;
      idea.createdAt = timestamp;
      idea.updatedAt = timestamp;
      await this.ideaRepository.save(idea);
      insertedCount = insertedCount + 1;
    }

    for (let index = 0; index < 6; index++) {
      const idea = new Idea();
      const content = this.sampleIdeaContent(index);
      const timestamp = todayStart + (8 + index) * this.HOUR_MS;
      idea.title = `${this.ideaPrefix}#${nextIndex}`;
      nextIndex = nextIndex + 1;
      idea.content = content;
      idea.length = content.length;
      idea.timestamp = timestamp;
      idea.createdAt = timestamp;
      idea.updatedAt = timestamp;
      await this.ideaRepository.save(idea);
      insertedCount = insertedCount + 1;
    }

    return insertedCount;
  }

  private async buildFocusData(): Promise<number> {
    const todayStart = this.resolveTodayStart();
    let insertedCount = 0;

    for (let index = 0; index < this.focusMinutePattern.length; index++) {
      const focus = new Focus();
      const dayOffset = this.focusMinutePattern.length - index;
      const dayStart = todayStart - dayOffset * this.DAY_MS;
      const startTime = dayStart + 20 * this.HOUR_MS;
      const durationSeconds = this.focusMinutePattern[index] * 60;
      focus.todoId = 0;
      focus.startTime = startTime;
      focus.endTime = startTime + durationSeconds * 1000;
      focus.duration = durationSeconds;
      focus.timestamp = startTime;
      focus.createdAt = startTime;
      focus.updatedAt = startTime;
      await this.focusRepository.save(focus);
      insertedCount = insertedCount + 1;
    }

    return insertedCount;
  }

  @Builder
  private buildActionSheetContent() {
    Column({ space: 12 }) {
      Text('ActionSheet 组件测试')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Text('当前页面通过 AppNav.openActionSheet 打开，关闭后会回到 sharedtest。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.app.theme.palette.textSecondary);

      Button('关闭 ActionSheet')
        .width('100%')
        .height(42)
        .fontColor(this.app.theme.palette.surface)
        .backgroundColor(this.app.theme.palette.primary)
        .onClick(() => {
          this.app.nav.back(false);
        });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 4, right: 4, top: 4, bottom: 8 });
  }

  @Builder
  private buildDetailCardContent() {
    Column({ space: 12 }) {
      Text('DetailCard 组件测试')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary);

      Text('该弹层用于验证 DetailCard 的遮罩、圆角和内容承载能力。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.app.theme.palette.textSecondary);

      Text('你可以在这里继续扩展复杂表单、详情信息或确认流程。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(4);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 0 }) {
        Row()
          .width('100%')
          .height(SafeAreaUtils.getTopInset());

        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(20)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
              .fontColor([this.app.theme.palette.textPrimary]);
          }
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .backgroundColor(this.app.theme.palette.transparent)
          .onClick(() => {
            this.onRequestDismiss();
          });

          Text('共享组件与数据测试')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary);

          Blank();
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center);

        Divider()
          .strokeWidth(0.5)
          .color(this.app.theme.palette.border);

        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 8 }) {
              Text('测试通用组件')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);
              Text('包含 #sym:FloatingActionButton、#sym:InteractableCard、#sym:ActionSheet/#sym:DetailCard、#sym:UndoNotificationStack。')
                .fontSize(12)
                .lineHeight(18)
                .fontColor(this.app.theme.palette.textSecondary);
            }
            .width('100%')
            .padding({ left: 4, right: 4 });

            Column({ space: 10 }) {
              Text('测试#sym:FloatingActionButton')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);

              Stack({ alignContent: Alignment.BottomEnd }) {
                Text('点击右下角悬浮按钮，验证图标、阴影和点击事件。')
                  .width('100%')
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textSecondary)
                  .padding({ left: 28, right: 120, top: 12, bottom: 12 });

                FloatingActionButton({
                  content: $r('sys.symbol.plus'),
                  onTap: () => {
                    this.safeToast('FloatingActionButton 点击成功');
                    this.pushLog('FloatingActionButton 点击成功');
                  },
                });
              }
              .width('100%')
              .height(124)
              .borderRadius(18)
              .backgroundColor(this.app.theme.palette.surfaceSecondary);
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface);

            Column({ space: 10 }) {
              Text('测试#sym:InteractableCard')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);

              ForEach(
                this.sampleCards,
                (item: DemoInteractableItem) => {
                  InteractableCard({
                    leftHint: '左滑删除',
                    rightHint: '右滑动作',
                    enableSwipeLeft: true,
                    enableSwipeRight: false,
                    onSwipeLeft: () => {
                      this.removeCard(item.id);
                    },
                    onCardTap: () => {
                      this.openDetailCardTest();
                    },
                  }) {
                    Column({ space: 6 }) {
                      Text(item.title)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.app.theme.palette.textPrimary);
                      Text(item.subtitle)
                        .fontSize(12)
                        .lineHeight(18)
                        .fontColor(this.app.theme.palette.textSecondary);
                    }
                    .alignItems(HorizontalAlign.Start)
                  }
                },
                (item: DemoInteractableItem) => item.id,
              );

              if (this.sampleCards.length <= 0) {
                Text('所有交互卡片已删除，可通过下方撤销通知恢复。')
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textTertiary)
                  .width('100%')
                  .padding(12)
                  .backgroundColor(this.app.theme.palette.surfaceSecondary)
                  .borderRadius(14);
              }
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface);

            Column({ space: 10 }) {
              Text('测试#sym:ActionSheet 和 #sym:DetailCard')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);

              Row({ space: 10 }) {
                Button('打开 ActionSheet')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(13)
                  .fontColor(this.app.theme.palette.surface)
                  .backgroundColor(this.app.theme.palette.primary)
                  .onClick(() => {
                    this.openActionSheetTest();
                  });

                Button('打开 DetailCard')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(13)
                  .fontColor(this.app.theme.palette.surface)
                  .backgroundColor(this.app.theme.palette.primary)
                  .onClick(() => {
                    this.openDetailCardTest();
                  });
              }
              .width('100%');
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface);

            Column({ space: 10 }) {
              Text('测试#sym:UndoNotificationStack')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);

              Button('模拟撤销通知')
                .width('100%')
                .height(42)
                .fontSize(13)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .onClick(() => {
                  this.enqueueUndoTask('这是一条撤销通知测试消息', null, -1);
                  this.pushLog('手动添加了一条撤销通知测试项');
                });

              Text(`当前待处理撤销任务: ${this.undoStackItems.length}`)
                .fontSize(12)
                .fontColor(this.app.theme.palette.textSecondary);
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface);

            Column({ space: 10 }) {
              Text('构建测试数据')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);

              Text('命名规则示例：测试日程#1、分类#1、测试待办#1、测试闪记#1')
                .fontSize(12)
                .lineHeight(18)
                .fontColor(this.app.theme.palette.textSecondary);

              Button('创建日程数据（本周 + 当天课程）')
                .width('100%')
                .height(42)
                .enabled(!this.buildingData)
                .fontSize(13)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .onClick(() => {
                  this.runBuildAction(
                    '创建日程数据',
                    async (): Promise<number> => await this.buildPlanData(),
                    '日程创建完成，新增 {count} 条',
                  );
                });

              Button('创建待办分类（最多四个）')
                .width('100%')
                .height(42)
                .enabled(!this.buildingData)
                .fontSize(13)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .onClick(() => {
                  this.runBuildAction(
                    '创建待办分类',
                    async (): Promise<number> => await this.buildTodoCategoryData(),
                    '分类创建完成，新增 {count} 个',
                  );
                });

              Button('创建待办（共十条）')
                .width('100%')
                .height(42)
                .enabled(!this.buildingData && this.hasRequiredTestCategories())
                .fontSize(13)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .onClick(() => {
                  this.runBuildAction(
                    '创建待办数据',
                    async (): Promise<number> => await this.buildTodoData(),
                    '待办创建完成，新增 {count} 条',
                  );
                });

              Text(`测试分类进度: ${this.testCategories.length}/4（待办按钮需先创建四个分类）`)
                .fontSize(12)
                .fontColor(this.app.theme.palette.textSecondary);

              Button('创建闪记（前30天 + 今天6条）')
                .width('100%')
                .height(42)
                .enabled(!this.buildingData)
                .fontSize(13)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .onClick(() => {
                  this.runBuildAction(
                    '创建闪记数据',
                    async (): Promise<number> => await this.buildIdeaData(),
                    '闪记创建完成，新增 {count} 条',
                  );
                });

              Button('创建专注记录（前六天）')
                .width('100%')
                .height(42)
                .enabled(!this.buildingData)
                .fontSize(13)
                .fontColor(this.app.theme.palette.surface)
                .backgroundColor(this.app.theme.palette.primary)
                .onClick(() => {
                  this.runBuildAction(
                    '创建专注记录',
                    async (): Promise<number> => await this.buildFocusData(),
                    '专注记录创建完成，新增 {count} 条',
                  );
                });
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface);

            Column({ space: 8 }) {
              Text('最近日志')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.app.theme.palette.textPrimary);

              if (this.logs.length <= 0) {
                Text('暂无日志')
                  .fontSize(12)
                  .fontColor(this.app.theme.palette.textTertiary);
              } else {
                ForEach(
                  this.logs,
                  (item: string, index: number) => {
                    Text(item)
                      .width('100%')
                      .fontSize(12)
                      .lineHeight(18)
                      .fontColor(this.app.theme.palette.textSecondary);
                  },
                  (item: string, index: number) => `${index}_${item}`,
                );
              }
            }
            .width('100%')
            .padding(14)
            .borderRadius(20)
            .backgroundColor(this.app.theme.palette.surface);

            Column()
              .height(44);
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background);

      UndoNotificationStack({
        tasks: this.undoStackItems,
        onUndo: (taskId: string) => {
          this.restoreCard(taskId);
        },
        onTimeout: (taskId: string) => {
          const task = this.findUndoTask(taskId);
          if (task !== null && task.item !== null) {
            this.pushLog(`${task.item.title} 删除已生效`);
          } else {
            this.pushLog('撤销测试通知已超时');
          }
          this.removeUndoTask(taskId);
        },
        onClose: (taskId: string) => {
          this.removeUndoTask(taskId);
        },
      });
    }
    .width('100%')
    .height('100%');
  }
}

@Builder
export function SharedInteractionTestPageBuilder(_name: string, _param: Object) {
  SharedInteractionTestPage();
}
