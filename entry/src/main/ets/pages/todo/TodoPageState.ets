import { Todo } from '../../core/models/Todo';
import { TodoCategory } from '../../core/models/TodoCategory';
import { TodoRepository } from '../../core/repositories/TodoRepository';
import { TodoCategoryRepository } from '../../core/repositories/TodoCategoryRepository';

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

  @Trace public undoVisible: boolean = false;
  @Trace public undoMessage: string = '';
  private pendingDeleteTodoId: string = '';
  private pendingDeleteTimerId: number = -1;
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
    const list: Array<TodoCategory> = await this.categoryRepository.findAll();
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
    if (this.selectedCategoryId.length > 0) {
      const exists = this.categories.some((item: TodoCategory) => this.safeTrim(item.id) === this.selectedCategoryId);
      if (!exists) {
        this.selectedCategoryId = '';
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
        const normalizedContent = this.safeTrim(list[i].content);
        if (normalizedContent.length > 0 && list[i].content !== normalizedContent) {
          list[i].content = normalizedContent;
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

  private syncVisibleTodos(): void {
    const categoryId = this.safeTrim(this.selectedCategoryId);
    if (categoryId.length === 0) {
      this.visibleTodos = this.todos.slice();
      return;
    }
    this.visibleTodos = this.todos.filter((item: Todo) => item.categoryId === categoryId).slice();
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

  async createTodo(content: string, categoryId: string): Promise<boolean> {
    await this.ensureDefaultCategories();
    if (this.categories.length === 0) {
      await this.refreshCategories();
    }
    const trimmed = this.safeTrim(content);
    if (trimmed.length === 0) {
      return false;
    }
    const todo = new Todo();
    todo.id = this.creatingTodoId.length > 0 ? this.creatingTodoId : this.newId('todo');
    todo.content = trimmed;
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

  async updateTodoContent(todoId: string, content: string): Promise<void> {
    const normalizedTodoId = this.safeTrim(todoId);
    if (normalizedTodoId.length === 0) {
      return;
    }
    const nextContent = this.safeTrim(content);
    const now = Date.now();
    let targetTodo: Todo | null = null;

    const localIndex = this.todos.findIndex((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);
    if (localIndex >= 0) {
      targetTodo = this.todos[localIndex];
      targetTodo.content = nextContent;
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
      targetTodo.content = nextContent;
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

    const localIndex = this.todos.findIndex((item: Todo) => this.safeTrim(item.id) === normalizedTodoId);
    if (localIndex >= 0) {
      targetTodo = this.todos[localIndex];
      targetTodo.isDone = nextDone;
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
      targetTodo.isDone = nextDone;
      targetTodo.updatedAt = now;
      targetTodo.timestamp = now;
    }

    if (targetTodo === null) {
      return;
    }
    await this.todoRepository.save(targetTodo);
    await this.refreshTodos();
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
    this.clearPendingDelete();
    this.pendingDeleteTodoId = todoId;
    this.undoMessage = '已删除待办';
    this.undoVisible = true;
    this.pendingDeleteTimerId = setTimeout(async () => {
      await this.commitDeleteTodo();
    }, 5000);
  }

  undoDelete(): void {
    this.clearPendingDelete();
    this.undoVisible = false;
  }

  async commitDeleteTodo(): Promise<void> {
    const todoId = this.pendingDeleteTodoId;
    this.clearPendingDelete();
    this.undoVisible = false;
    if (todoId.length === 0) {
      return;
    }
    await this.todoRepository.removeById(todoId);
    await this.refreshTodos();
  }

  closeUndo(): void {
    this.undoVisible = false;
  }

  private clearPendingDelete(): void {
    this.pendingDeleteTodoId = '';
    if (this.pendingDeleteTimerId >= 0) {
      clearTimeout(this.pendingDeleteTimerId);
      this.pendingDeleteTimerId = -1;
    }
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
