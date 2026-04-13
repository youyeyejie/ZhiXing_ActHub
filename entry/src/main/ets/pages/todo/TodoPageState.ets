import { Todo } from '../../core/models/Todo';
import { TodoCategory } from '../../core/models/TodoCategory';
import { TodoRepository } from '../../core/repositories/TodoRepository';
import { TodoCategoryRepository } from '../../core/repositories/TodoCategoryRepository';
import { UndoStackItem } from '../../components/feedback/UndoNotificationStack';

class TodoUndoTask {
  taskId: string;
  todo: Todo;
  originalIndex: number;
  timerId: number;
  deadlineMs: number;

  constructor(taskId: string, todo: Todo, originalIndex: number, timerId: number, deadlineMs: number) {
    this.taskId = taskId;
    this.todo = todo;
    this.originalIndex = originalIndex;
    this.timerId = timerId;
    this.deadlineMs = deadlineMs;
  }
}

@ObservedV2
export class TodoPageState {
  private todoRepository: TodoRepository = new TodoRepository();
  private categoryRepository: TodoCategoryRepository = new TodoCategoryRepository();

  private readonly categoryColorPalette: Array<string> = [
    '#3B82F6', // blue
    '#7C3AED', // violet
    '#22C55E', // green
    '#F59E0B', // amber
    '#EF4444', // red
    '#06B6D4', // cyan
    '#A855F7', // purple
    '#10B981', // emerald
  ];

  @Trace public categories: Array<TodoCategory> = [];
  @Trace public selectedCategoryId: string = '';
  @Trace public todos: Array<Todo> = [];
  @Trace public visibleTodos: Array<Todo> = [];

  @Trace public isCategoryEditorVisible: boolean = false;
  @Trace public isTodoEditorVisible: boolean = false;
  @Trace public isTodoDetailVisible: boolean = false;

  @Trace public editingTodoId: string = '';
  @Trace public creatingTodoId: string = '';
  @Trace public undoTasks: Array<TodoUndoTask> = [];
  private undoTaskSeq: number = 0;
  private readonly defaultCategoryName: string = '学习';

  private refreshTask: Promise<void> | null = null;
  private ensureDefaultCategoryTask: Promise<void> | null = null;

  private safeTrim(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private copyTodo(source: Todo): Todo {
    const todo = new Todo();
    todo.id = source.id;
    todo.content = source.content;
    todo.detail = source.detail;
    todo.timestamp = source.timestamp;
    todo.categoryId = source.categoryId;
    todo.isDone = source.isDone;
    todo.inFocus = source.inFocus;
    todo.createdAt = source.createdAt;
    todo.updatedAt = source.updatedAt;
    return todo;
  }

  async refreshAll(): Promise<void> {
    if (this.refreshTask !== null) {
      return this.refreshTask;
    }
    this.refreshTask = (async (): Promise<void> => {
      try {
        await this.refreshAllInternal();
      } finally {
        this.refreshTask = null;
      }
    })();
    return this.refreshTask;
  }

  private async refreshAllInternal(): Promise<void> {
    await this.ensureDefaultCategories();
    await this.refreshCategories();
    await this.refreshTodos();
  }

  async refreshCategories(): Promise<void> {
    const previousSelectedId = this.safeTrim(this.selectedCategoryId);
    let previousSelectedName = '';
    if (previousSelectedId.length > 0) {
      const localSelected = this.categories.find((item: TodoCategory) => this.safeTrim(item.id) === previousSelectedId);
      if (localSelected) {
        previousSelectedName = this.safeTrim(localSelected.category);
      }
    }

    const list: Array<TodoCategory> = await this.categoryRepository.findAll();
    if (previousSelectedId.length > 0 && previousSelectedName.length === 0) {
      const fromList = list.find((item: TodoCategory) => this.safeTrim(item.id) === previousSelectedId);
      if (fromList) {
        previousSelectedName = this.safeTrim(fromList.category);
      }
    }
    list.sort((a: TodoCategory, b: TodoCategory) => {
      const aName = this.safeTrim(a.category);
      const bName = this.safeTrim(b.category);
      if (aName === this.defaultCategoryName && bName !== this.defaultCategoryName) {
        return -1;
      }
      if (bName === this.defaultCategoryName && aName !== this.defaultCategoryName) {
        return 1;
      }
      return aName.localeCompare(bName);
    });

    // 防止历史 bug 造成的同名重复分类在 UI 中多次出现（尤其是默认“学习”）。
    const deduped: Array<TodoCategory> = [];
    const seen: Set<string> = new Set<string>();
    for (let i = 0; i < list.length; i++) {
      const nameKey = this.safeTrim(list[i].category);
      if (nameKey.length === 0) {
        continue;
      }
      if (seen.has(nameKey)) {
        continue;
      }
      seen.add(nameKey);
      deduped.push(list[i]);
    }

    // 给缺失颜色的旧数据补齐（颜色不在 UI 暴露，仅用于渲染）。
    for (let i = 0; i < deduped.length; i++) {
      const normalizedId = this.safeTrim(deduped[i].id);
      if (normalizedId.length === 0) {
        deduped[i].id = this.newId('cat');
        deduped[i].updatedAt = Date.now();
        await this.categoryRepository.save(deduped[i]);
      } else if (deduped[i].id !== normalizedId) {
        deduped[i].id = normalizedId;
        deduped[i].updatedAt = Date.now();
        await this.categoryRepository.save(deduped[i]);
      }

      const normalizedName = this.safeTrim(deduped[i].category);
      if (normalizedName.length > 0) {
        deduped[i].category = normalizedName;
      }

      const normalizedColor = this.safeTrim(deduped[i].color);
      if (normalizedColor.length === 0) {
        deduped[i].color = this.categoryColorPalette[i % this.categoryColorPalette.length];
        deduped[i].updatedAt = Date.now();
        await this.categoryRepository.save(deduped[i]);
        continue;
      }
      if (deduped[i].color !== normalizedColor) {
        deduped[i].color = normalizedColor;
        deduped[i].updatedAt = Date.now();
        await this.categoryRepository.save(deduped[i]);
      }
    }

    this.categories = deduped;
    const currentSelectedId = this.safeTrim(this.selectedCategoryId);
    if (currentSelectedId.length > 0) {
      const exists = this.categories.some((item: TodoCategory) => this.safeTrim(item.id) === currentSelectedId);
      if (!exists) {
        let remappedId = '';
        const fallbackName = previousSelectedName.length > 0 ? previousSelectedName : '';
        if (fallbackName.length > 0) {
          const remapped = this.categories.find((item: TodoCategory) => this.safeTrim(item.category) === fallbackName);
          if (remapped) {
            remappedId = this.safeTrim(remapped.id);
          }
        }
        this.selectedCategoryId = remappedId;
      }
    }
    this.syncVisibleTodos();
  }

  async refreshTodos(): Promise<void> {
    const list: Array<Todo> = await this.todoRepository.findAll();
    // 强制所有待办都有合法分类：缺失或被删除的分类统一回落到默认分类（学习）。
    if (this.categories.length === 0) {
      await this.ensureDefaultCategories();
      await this.refreshCategories();
    }
    const validCategoryIds = new Set<string>(this.categories.map((item: TodoCategory) => this.safeTrim(item.id)));
    const defaultCategoryId = this.getDefaultCategoryId();
    const fallbackCategoryId = defaultCategoryId.length > 0 ? defaultCategoryId :
      (this.categories.length > 0 ? this.safeTrim(this.categories[0].id) : '');
    if (fallbackCategoryId.length > 0) {
      for (let i = 0; i < list.length; i++) {
        const normalizedTitle = this.safeTrim(list[i].content);
        if (list[i].content !== normalizedTitle) {
          list[i].content = normalizedTitle;
          list[i].updatedAt = Date.now();
          await this.todoRepository.save(list[i]);
        }

        const normalizedDetail = this.safeTrim(list[i].detail);
        if (list[i].detail !== normalizedDetail) {
          list[i].detail = normalizedDetail;
          list[i].updatedAt = Date.now();
          await this.todoRepository.save(list[i]);
        }

        const normalizedCategoryId = this.safeTrim(list[i].categoryId);
        const invalid = normalizedCategoryId.length === 0 || !validCategoryIds.has(normalizedCategoryId);
        if (invalid) {
          list[i].categoryId = fallbackCategoryId;
          list[i].updatedAt = Date.now();
          await this.todoRepository.save(list[i]);
          continue;
        }
        if (list[i].categoryId !== normalizedCategoryId) {
          list[i].categoryId = normalizedCategoryId;
          list[i].updatedAt = Date.now();
          await this.todoRepository.save(list[i]);
        }
      }
    }
    const sorted: Array<Todo> = list.slice();
    sorted.sort((a: Todo, b: Todo) => b.timestamp - a.timestamp);
    this.todos = sorted;
    this.syncVisibleTodos();
  }

  async ensureDefaultCategories(): Promise<void> {
    if (this.ensureDefaultCategoryTask !== null) {
      return this.ensureDefaultCategoryTask;
    }
    this.ensureDefaultCategoryTask = (async (): Promise<void> => {
      try {
        await this.ensureDefaultCategoriesInternal();
      } finally {
        this.ensureDefaultCategoryTask = null;
      }
    })();
    return this.ensureDefaultCategoryTask;
  }

  private async ensureDefaultCategoriesInternal(): Promise<void> {
    // 这里避免使用 where/exists 链式查询，规避潜在 QueryBuilder 条件残留导致的“列表消失”。
    const existing: Array<TodoCategory> = await this.categoryRepository.findAll();
    const hasLearning = existing.some((item: TodoCategory) => this.safeTrim(item.category) === this.defaultCategoryName);
    if (hasLearning) {
      return;
    }

    const now = Date.now();
    const cat = new TodoCategory();
    cat.id = this.newId('cat');
    cat.category = this.defaultCategoryName;
    cat.color = this.categoryColorPalette[0];
    cat.createdAt = now;
    cat.updatedAt = now;
    await this.categoryRepository.insert(cat);
  }

  getDefaultCategoryId(): string {
    const found = this.categories.find((item: TodoCategory) => this.safeTrim(item.category) === this.defaultCategoryName);
    return found ? this.safeTrim(found.id) : '';
  }

  openCategoryEditor(): void {
    this.isCategoryEditorVisible = true;
  }

  closeCategoryEditor(): void {
    this.isCategoryEditorVisible = false;
  }

  selectCategory(categoryId: string): void {
    this.selectedCategoryId = this.safeTrim(categoryId);
    this.syncVisibleTodos();
  }

  openCreateTodo(): void {
    this.creatingTodoId = this.newId('todo');
    this.editingTodoId = '';
    this.isTodoEditorVisible = true;
  }

  closeTodoEditor(): void {
    this.isTodoEditorVisible = false;
    this.creatingTodoId = '';
  }

  openTodoDetail(todoId: string): void {
    this.editingTodoId = todoId;
    this.isTodoDetailVisible = true;
  }

  closeTodoDetail(): void {
    this.isTodoDetailVisible = false;
    this.editingTodoId = '';
  }

  private sortVisibleTodoList(list: Array<Todo>): Array<Todo> {
    const sorted = list.slice();
    sorted.sort((a: Todo, b: Todo) => {
      const aDone = a.isDone === 1 ? 1 : 0;
      const bDone = b.isDone === 1 ? 1 : 0;
      if (aDone !== bDone) {
        return aDone - bDone;
      }
      if (a.timestamp === b.timestamp) {
        return b.updatedAt - a.updatedAt;
      }
      return b.timestamp - a.timestamp;
    });
    return sorted;
  }

  private syncVisibleTodos(): void {
    const categoryId = this.safeTrim(this.selectedCategoryId);
    if (categoryId.length === 0) {
      const filtered = this.todos.filter((item: Todo) => !this.hasUndoTaskForTodo(item.id));
      this.visibleTodos = this.sortVisibleTodoList(filtered);
      return;
    }
    const filtered = this.todos.filter((item: Todo) => {
      return item.categoryId === categoryId && !this.hasUndoTaskForTodo(item.id);
    });
    this.visibleTodos = this.sortVisibleTodoList(filtered);
  }

  resolveCategoryName(categoryId: string): string {
    const resolvedId = this.safeTrim(categoryId);
    if (resolvedId.length === 0) {
      return this.defaultCategoryName;
    }
    const found = this.categories.find((item: TodoCategory) => this.safeTrim(item.id) === resolvedId);
    return found ? found.category : this.defaultCategoryName;
  }

  resolveCategoryColor(categoryId: string): string {
    const resolvedId = this.safeTrim(categoryId);
    if (resolvedId.length === 0) {
      const learning = this.categories.find((item: TodoCategory) => item.category === this.defaultCategoryName);
      return learning ? learning.color : this.categoryColorPalette[0];
    }
    const found = this.categories.find((item: TodoCategory) => this.safeTrim(item.id) === resolvedId);
    return found ? found.color : this.categoryColorPalette[0];
  }

  async createTodo(title: string, detail: string, categoryId: string): Promise<boolean> {
    await this.ensureDefaultCategories();
    if (this.categories.length === 0) {
      await this.refreshCategories();
    }
    const trimmedTitle = this.safeTrim(title);
    if (trimmedTitle.length === 0) {
      return false;
    }
    const trimmedDetail = this.safeTrim(detail);
    const todo = new Todo();
    todo.id = this.creatingTodoId.length > 0 ? this.creatingTodoId : this.newId('todo');
    todo.content = trimmedTitle;
    todo.detail = trimmedDetail;
    const defaultCategoryId = this.getDefaultCategoryId();
    const candidateId = this.safeTrim(categoryId);
    const hasCandidate = candidateId.length > 0 && this.categories.some((item: TodoCategory) => this.safeTrim(item.id) === candidateId);
    const resolvedCategoryId = hasCandidate ? candidateId :
      (defaultCategoryId.length > 0 ? defaultCategoryId : (this.categories.length > 0 ? this.safeTrim(this.categories[0].id) : ''));
    if (resolvedCategoryId.length === 0) {
      return false;
    }
    todo.categoryId = resolvedCategoryId;
    todo.isDone = 0;
    todo.inFocus = 0;
    todo.timestamp = Date.now();
    todo.createdAt = Date.now();
    todo.updatedAt = Date.now();
    const ok = await this.todoRepository.insert(todo);
    if (!ok) {
      return false;
    }
    await this.refreshTodos();
    return true;
  }

  async updateTodoTitle(todoId: string, title: string): Promise<void> {
    const normalizedTodoId = this.safeTrim(todoId);
    if (normalizedTodoId.length === 0) {
      return;
    }
    const nextTitle = this.safeTrim(title);
    const now = Date.now();
    let targetTodo: Todo | null = null;

    const localIndex = this.todos.findIndex((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);
    if (localIndex >= 0) {
      targetTodo = this.todos[localIndex];
      targetTodo.content = nextTitle;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
      this.todos = this.todos.slice();
      this.syncVisibleTodos();
    }

    if (targetTodo === null) {
      targetTodo = await this.todoRepository.findById(normalizedTodoId);
      if (!targetTodo) {
        return;
      }
      targetTodo.content = nextTitle;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
    }

    if (targetTodo === null) {
      return;
    }
    await this.todoRepository.save(targetTodo);
    await this.refreshTodos();
  }

  async updateTodoDetail(todoId: string, detail: string): Promise<void> {
    const normalizedTodoId = this.safeTrim(todoId);
    if (normalizedTodoId.length === 0) {
      return;
    }
    const nextDetail = this.safeTrim(detail);
    const now = Date.now();
    let targetTodo: Todo | null = null;

    const localIndex = this.todos.findIndex((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);
    if (localIndex >= 0) {
      targetTodo = this.todos[localIndex];
      targetTodo.detail = nextDetail;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
      this.todos = this.todos.slice();
      this.syncVisibleTodos();
    }

    if (targetTodo === null) {
      targetTodo = await this.todoRepository.findById(normalizedTodoId);
      if (!targetTodo) {
        return;
      }
      targetTodo.detail = nextDetail;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
    }

    if (targetTodo === null) {
      return;
    }
    await this.todoRepository.save(targetTodo);
    await this.refreshTodos();
  }

  async updateTodoCategory(todoId: string, categoryId: string): Promise<void> {
    await this.ensureDefaultCategories();
    if (this.categories.length === 0) {
      await this.refreshCategories();
    }
    const normalizedTodoId = this.safeTrim(todoId);
    if (normalizedTodoId.length === 0) {
      return;
    }
    const candidateId = this.safeTrim(categoryId);
    const valid = candidateId.length > 0 && this.categories.some((item: TodoCategory) => this.safeTrim(item.id) === candidateId);
    const fallbackCategoryId = this.getDefaultCategoryId().length > 0 ? this.getDefaultCategoryId() :
      (this.categories.length > 0 ? this.safeTrim(this.categories[0].id) : '');
    const resolvedCategoryId = valid ? candidateId : fallbackCategoryId;
    const now = Date.now();
    let targetTodo: Todo | null = null;

    const localIndex = this.todos.findIndex((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);
    if (localIndex >= 0) {
      targetTodo = this.todos[localIndex];
      targetTodo.categoryId = resolvedCategoryId;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
      this.todos = this.todos.slice();
      this.syncVisibleTodos();
    }

    if (targetTodo === null) {
      targetTodo = await this.todoRepository.findById(normalizedTodoId);
      if (!targetTodo) {
        return;
      }
      targetTodo.categoryId = resolvedCategoryId;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
    }

    if (targetTodo === null) {
      return;
    }
    await this.todoRepository.save(targetTodo);
    await this.refreshTodos();
  }

  async toggleDone(todoId: string, isDone: boolean): Promise<void> {
    const normalizedTodoId = this.safeTrim(todoId);
    if (normalizedTodoId.length === 0) {
      return;
    }
    const nextDone = isDone ? 1 : 0;
    const now = Date.now();
    let targetTodo: Todo | null = null;
    const hasLocalTodo = this.todos.some((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);

    const localIndex = this.todos.findIndex((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);
    if (localIndex >= 0) {
      targetTodo = this.todos[localIndex];
      targetTodo.isDone = nextDone;
      targetTodo.updatedAt = now;
      this.todos = this.todos.slice();
      this.syncVisibleTodos();
    }

    if (targetTodo === null) {
      targetTodo = await this.todoRepository.findById(normalizedTodoId);
      if (!targetTodo) {
        return;
      }
      targetTodo.isDone = nextDone;
      targetTodo.updatedAt = now;
    }

    if (targetTodo === null) {
      return;
    }
    await this.todoRepository.save(targetTodo);
    if (!hasLocalTodo) {
      await this.refreshTodos();
    }
  }

  async addCategory(name: string): Promise<boolean> {
    await this.ensureDefaultCategories();
    const trimmed = this.safeTrim(name);
    if (trimmed.length === 0) {
      return false;
    }
    // 同名不重复创建：不使用 where/exists，避免 QueryBuilder 条件残留。
    const existing: Array<TodoCategory> = await this.categoryRepository.findAll();
    const exists = existing.some((item: TodoCategory) => this.safeTrim(item.category) === trimmed);
    if (exists) {
      return false;
    }
    const cat = new TodoCategory();
    cat.id = this.newId('cat');
    cat.category = trimmed;
    cat.color = this.pickColorForNewCategory();
    cat.createdAt = Date.now();
    cat.updatedAt = Date.now();
    const ok = await this.categoryRepository.insert(cat);
    if (!ok) {
      return false;
    }
    await this.refreshCategories();
    return true;
  }

  async updateCategoryName(categoryId: string, name: string): Promise<void> {
    const normalizedId = this.safeTrim(categoryId);
    const trimmed = this.safeTrim(name);
    if (normalizedId.length === 0 || trimmed.length === 0) {
      return;
    }
    const category = await this.categoryRepository.findById(normalizedId);
    if (!category) {
      return;
    }
    const currentName = this.safeTrim(category.category);
    if (currentName === trimmed) {
      return;
    }
    category.category = trimmed;
    category.updatedAt = Date.now();
    await this.categoryRepository.save(category);
    await this.refreshCategories();
  }

  async removeCategory(categoryId: string, cascadeDeleteTodos: boolean = false): Promise<boolean> {
    const normalizedId = this.safeTrim(categoryId);
    if (normalizedId.length === 0) {
      return false;
    }
    await this.ensureDefaultCategories();
    if (this.categories.length === 0) {
      await this.refreshCategories();
    }

    const removing = this.categories.find((item: TodoCategory) => this.safeTrim(item.id) === normalizedId);
    if (!removing) {
      return false;
    }
    if (this.safeTrim(removing.category) === this.defaultCategoryName) {
      // 保留默认“学习”分类，保证至少存在一个分类。
      return false;
    }

    if (cascadeDeleteTodos) {
      const todos = await this.todoRepository.findAll();
      for (let i = 0; i < todos.length; i++) {
        if (this.safeTrim(todos[i].categoryId) === normalizedId) {
          await this.todoRepository.removeById(this.safeTrim(todos[i].id));
        }
      }
    } else {
      const fallbackCategoryId = this.getDefaultCategoryId().length > 0 ? this.getDefaultCategoryId() :
        (this.categories.length > 0 ? this.categories[0].id : '');
      if (fallbackCategoryId.length > 0) {
        const todos = await this.todoRepository.findAll();
        for (let i = 0; i < todos.length; i++) {
          if (this.safeTrim(todos[i].categoryId) === normalizedId) {
            todos[i].categoryId = fallbackCategoryId;
            todos[i].updatedAt = Date.now();
            await this.todoRepository.save(todos[i]);
          }
        }
      }
    }
    await this.categoryRepository.removeById(normalizedId);
    if (this.selectedCategoryId === normalizedId) {
      this.selectedCategoryId = '';
    }
    await this.refreshCategories();
    await this.refreshTodos();
    return true;
  }

  requestDeleteTodo(todoId: string): void {
    const normalizedId = this.safeTrim(todoId);
    if (normalizedId.length === 0) {
      return;
    }
    const target = this.todos.find((item: Todo) => this.safeTrim(item.id) === normalizedId);
    if (!target) {
      return;
    }
    if (this.hasUndoTaskForTodo(normalizedId)) {
      return;
    }

    const originalIndex = this.findTodoIndexById(normalizedId);
    const snapshot = this.copyTodo(target);
    const taskId = `todo_delete_${this.undoTaskSeq}`;
    this.undoTaskSeq = this.undoTaskSeq + 1;
    const deadlineMs = Date.now() + 5000;
    const timerId = setTimeout(async () => {
      await this.commitDeleteTodo(taskId);
    }, 5000);
    this.undoTasks = [...this.undoTasks, new TodoUndoTask(taskId, snapshot, originalIndex, timerId, deadlineMs)];
    this.todos = this.todos.filter((item: Todo) => this.safeTrim(item.id) !== normalizedId);
    if (this.safeTrim(this.editingTodoId) === normalizedId) {
      this.closeTodoDetail();
    }
    this.syncVisibleTodos();
  }

  undoDelete(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.closeUndo(taskId);
    const snapshotId = this.safeTrim(task.todo.id);
    const exists = this.todos.some((item: Todo) => this.safeTrim(item.id) === snapshotId);
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.todos.length));
      const before = this.todos.slice(0, insertIndex);
      const after = this.todos.slice(insertIndex);
      this.todos = [...before, task.todo, ...after];
    }
    this.syncVisibleTodos();
  }

  async commitDeleteTodo(taskId: string): Promise<void> {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    const todoId = this.safeTrim(task.todo.id);
    this.closeUndo(taskId);
    if (todoId.length === 0) {
      return;
    }
    await this.todoRepository.removeById(todoId);
    await this.refreshTodos();
  }

  closeUndo(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    if (task.timerId >= 0) {
      clearTimeout(task.timerId);
    }
    this.undoTasks = this.undoTasks.filter((item: TodoUndoTask) => item.taskId !== taskId);
  }

  buildUndoStackItems(): Array<UndoStackItem> {
    const list: Array<UndoStackItem> = [];
    for (let i = 0; i < this.undoTasks.length; i++) {
      const task = this.undoTasks[i];
      const title = this.safeTrim(task.todo.content);
      list.push(
        new UndoStackItem(
          task.taskId,
          `${title.length > 0 ? title : '待办'} 已删除`,
          '撤销',
          5000,
          task.deadlineMs,
        )
      );
    }
    return list;
  }

  private findUndoTask(taskId: string): TodoUndoTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  private hasUndoTaskForTodo(todoId: string): boolean {
    const normalizedId = this.safeTrim(todoId);
    return this.undoTasks.some((task: TodoUndoTask) => this.safeTrim(task.todo.id) === normalizedId);
  }

  private findTodoIndexById(todoId: string): number {
    for (let i = 0; i < this.todos.length; i++) {
      if (this.safeTrim(this.todos[i].id) === todoId) {
        return i;
      }
    }
    return this.todos.length;
  }

  private pickColorForNewCategory(): string {
    const index = this.categories.length;
    return this.categoryColorPalette[index % this.categoryColorPalette.length];
  }

  private newId(prefix: string): string {
    const millis = Date.now();
    const rand = Math.floor(Math.random() * 1_000_000);
    return `${prefix}_${millis}_${rand}`;
  }
}

const TODO_PAGE_STATE: TodoPageState = new TodoPageState();

export function useTodoPageState(): TodoPageState {
  return TODO_PAGE_STATE;
}
