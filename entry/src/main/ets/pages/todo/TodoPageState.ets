import { Todo } from "../../core/models/Todo";
import { TodoCategory } from "../../core/models/TodoCategory";
import { TodoRepository } from "../../core/repositories/TodoRepository";
import { TodoCategoryRepository } from "../../core/repositories/TodoCategoryRepository";
import { UndoStackItem } from "../../components/feedback/UndoNotificationStack";
import { AppState, useAppState } from "../../app/AppStates";

class TodoUndoTask {
  taskId: string;
  todo: Todo;
  originalIndex: number;
  timerId: number;
  deadlineMs: number;

  constructor(
    taskId: string,
    todo: Todo,
    originalIndex: number,
    timerId: number,
    deadlineMs: number,
  ) {
    this.taskId = taskId;
    this.todo = todo;
    this.originalIndex = originalIndex;
    this.timerId = timerId;
    this.deadlineMs = deadlineMs;
  }
}

@ObservedV2
export class TodoCardItem {
  @Trace id: number = 0;
  @Trace title: string = "";
  @Trace categoryId: number = 0;
  @Trace categoryName: string = "";
  @Trace categoryColor: string = "";
  @Trace isDone: number = 0;
  @Trace inFocus: number = 0;
  @Trace createdAt: number = 0;
  @Trace timestamp: number = 0;
  @Trace updatedAt: number = 0;

  applyFrom(todo: Todo, title: string, categoryName: string, categoryColor: string): void {
    this.id = todo.id;
    this.title = title;
    this.categoryId = todo.categoryId;
    this.categoryName = categoryName;
    this.categoryColor = categoryColor;
    this.isDone = todo.isDone;
    this.inFocus = todo.inFocus;
    this.createdAt = todo.createdAt;
    this.timestamp = todo.timestamp;
    this.updatedAt = todo.updatedAt;
  }
}

@ObservedV2
export class TodoPageState {
  private app: AppState = useAppState();
  private todoRepository: TodoRepository = new TodoRepository();
  private categoryRepository: TodoCategoryRepository = new TodoCategoryRepository();

  private getCategoryColorPalette(): Array<string> {
    return [
      this.app.theme.palette.accentBlue,
      this.app.theme.palette.accentViolet,
      this.app.theme.palette.accentGreen,
      this.app.theme.palette.accentAmber,
      this.app.theme.palette.accentRed,
      this.app.theme.palette.accentCyan,
      this.app.theme.palette.accentPurple,
      this.app.theme.palette.accentEmerald,
    ];
  }

  @Trace public categories: Array<TodoCategory> = [];
  @Trace public selectedCategoryId: number = 0;
  @Trace public todos: Array<Todo> = [];
  @Trace public visibleTodos: Array<Todo> = [];
  @Trace public visibleTodoCards: Array<TodoCardItem> = [];

  @Trace public isCategoryEditorVisible: boolean = false;
  @Trace public isTodoEditorVisible: boolean = false;
  @Trace public isTodoDetailVisible: boolean = false;

  @Trace public editingTodoId: number = 0;
  @Trace public undoTasks: Array<TodoUndoTask> = [];
  @Trace public pendingRestoreMoveTodoIds: Array<number> = [];
  private undoTaskSeq: number = 0;
  private readonly defaultCategoryName: string = "学习";

  private refreshTask: Promise<void> | null = null;
  private ensureDefaultCategoryTask: Promise<void> | null = null;
  private todoCardItemMap: Map<number, TodoCardItem> = new Map<number, TodoCardItem>();

  private safeTrim(value: string): string {
    const text = `${value}`.trim();
    if (text === "undefined" || text === "null") {
      return "";
    }
    return text;
  }

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
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

  private resolveTodoCardTitle(todo: Todo): string {
    const title = this.safeTrim(todo.content);
    return title.length > 0 ? title : "未命名待办";
  }

  private syncVisibleTodoCards(): void {
    const nextCardMap: Map<number, TodoCardItem> = new Map<number, TodoCardItem>();
    for (let i = 0; i < this.todos.length; i++) {
      const todo = this.todos[i];
      const todoId = this.normalizeId(todo.id);
      if (todoId <= 0) {
        continue;
      }
      let cardItem = this.todoCardItemMap.get(todoId);
      if (cardItem === undefined) {
        cardItem = new TodoCardItem();
      }
      cardItem.applyFrom(
        todo,
        this.resolveTodoCardTitle(todo),
        this.resolveCategoryName(todo.categoryId),
        this.resolveCategoryColor(todo.categoryId),
      );
      nextCardMap.set(todoId, cardItem);
    }
    this.todoCardItemMap = nextCardMap;

    const nextVisibleCards: Array<TodoCardItem> = [];
    for (let i = 0; i < this.visibleTodos.length; i++) {
      const todoId = this.normalizeId(this.visibleTodos[i].id);
      if (todoId <= 0) {
        continue;
      }
      const cardItem = this.todoCardItemMap.get(todoId);
      if (cardItem !== undefined) {
        nextVisibleCards.push(cardItem);
      }
    }
    this.visibleTodoCards = nextVisibleCards;
  }

  private compareTodoByCreatedAtDesc(a: Todo, b: Todo): number {
    const aCreatedAt = a.createdAt > 0 ? a.createdAt : 0;
    const bCreatedAt = b.createdAt > 0 ? b.createdAt : 0;
    if (aCreatedAt !== bCreatedAt) {
      return bCreatedAt - aCreatedAt;
    }
    return this.normalizeId(b.id) - this.normalizeId(a.id);
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
    const previousSelectedId = this.normalizeId(this.selectedCategoryId);
    let previousSelectedName = "";
    if (previousSelectedId > 0) {
      const localSelected = this.categories.find(
        (item: TodoCategory) => this.normalizeId(item.id) === previousSelectedId,
      );
      if (localSelected) {
        previousSelectedName = this.safeTrim(localSelected.category);
      }
    }

    const list: Array<TodoCategory> = await this.categoryRepository.findAll();
    if (previousSelectedId > 0 && previousSelectedName.length === 0) {
      const fromList = list.find(
        (item: TodoCategory) => this.normalizeId(item.id) === previousSelectedId,
      );
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
      const normalizedName = this.safeTrim(deduped[i].category);
      if (normalizedName.length > 0) {
        deduped[i].category = normalizedName;
      }

      const normalizedColor = this.safeTrim(deduped[i].color);
      if (normalizedColor.length === 0) {
        const colorPalette = this.getCategoryColorPalette();
        deduped[i].color = colorPalette[i % colorPalette.length];
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
    const currentSelectedId = this.normalizeId(this.selectedCategoryId);
    if (currentSelectedId > 0) {
      const exists = this.categories.some(
        (item: TodoCategory) => this.normalizeId(item.id) === currentSelectedId,
      );
      if (!exists) {
        let remappedId = 0;
        const fallbackName = previousSelectedName.length > 0 ? previousSelectedName : "";
        if (fallbackName.length > 0) {
          const remapped = this.categories.find(
            (item: TodoCategory) => this.safeTrim(item.category) === fallbackName,
          );
          if (remapped) {
            remappedId = this.normalizeId(remapped.id);
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
    const validCategoryIds = new Set<number>(
      this.categories.map((item: TodoCategory) => this.normalizeId(item.id)),
    );
    const defaultCategoryId = this.getDefaultCategoryId();
    const fallbackCategoryId =
      defaultCategoryId > 0
        ? defaultCategoryId
        : this.categories.length > 0
          ? this.normalizeId(this.categories[0].id)
          : 0;
    if (fallbackCategoryId > 0) {
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

        const normalizedCategoryId = this.normalizeId(list[i].categoryId);
        const invalid = normalizedCategoryId <= 0 || !validCategoryIds.has(normalizedCategoryId);
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
    sorted.sort((a: Todo, b: Todo) => this.compareTodoByCreatedAtDesc(a, b));
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
    const hasLearning = existing.some(
      (item: TodoCategory) => this.safeTrim(item.category) === this.defaultCategoryName,
    );
    if (hasLearning) {
      return;
    }

    const now = Date.now();
    const cat = new TodoCategory();
    cat.category = this.defaultCategoryName;
    cat.color = this.getCategoryColorPalette()[0];
    cat.createdAt = now;
    cat.updatedAt = now;
    await this.categoryRepository.insert(cat);
  }

  getDefaultCategoryId(): number {
    const found = this.categories.find(
      (item: TodoCategory) => this.safeTrim(item.category) === this.defaultCategoryName,
    );
    return found ? this.normalizeId(found.id) : 0;
  }

  openCategoryEditor(): void {
    this.isCategoryEditorVisible = true;
  }

  closeCategoryEditor(): void {
    this.isCategoryEditorVisible = false;
  }

  selectCategory(categoryId: number): void {
    this.selectedCategoryId = this.normalizeId(categoryId);
    this.syncVisibleTodos();
  }

  openCreateTodo(): void {
    this.editingTodoId = 0;
    this.isTodoEditorVisible = true;
  }

  closeTodoEditor(): void {
    this.isTodoEditorVisible = false;
  }

  openTodoDetail(todoId: number): void {
    this.editingTodoId = this.normalizeId(todoId);
    this.isTodoDetailVisible = true;
  }

  closeTodoDetail(): void {
    this.isTodoDetailVisible = false;
    this.editingTodoId = 0;
  }

  private sortVisibleTodoList(list: Array<Todo>): Array<Todo> {
    const sorted = list.slice();
    sorted.sort((a: Todo, b: Todo) => {
      const aDone = a.isDone === 1 ? 1 : 0;
      const bDone = b.isDone === 1 ? 1 : 0;
      if (aDone !== bDone) {
        return aDone - bDone;
      }
      return this.compareTodoByCreatedAtDesc(a, b);
    });

    if (this.pendingRestoreMoveTodoIds.length === 0) {
      return sorted;
    }

    const pendingSet: Set<number> = new Set<number>(
      this.pendingRestoreMoveTodoIds.map((id: number) => this.normalizeId(id)),
    );
    const normal: Array<Todo> = [];
    const pending: Array<Todo> = [];
    for (let i = 0; i < sorted.length; i++) {
      const todoId = this.normalizeId(sorted[i].id);
      if (todoId > 0 && pendingSet.has(todoId)) {
        pending.push(sorted[i]);
      } else {
        normal.push(sorted[i]);
      }
    }
    return [...normal, ...pending];
  }

  private syncVisibleTodos(): void {
    const categoryId = this.normalizeId(this.selectedCategoryId);
    if (categoryId <= 0) {
      const filtered = this.todos.filter((item: Todo) => !this.hasUndoTaskForTodo(item.id));
      this.visibleTodos = this.sortVisibleTodoList(filtered);
      this.syncVisibleTodoCards();
      return;
    }
    const filtered = this.todos.filter((item: Todo) => {
      return this.normalizeId(item.categoryId) === categoryId && !this.hasUndoTaskForTodo(item.id);
    });
    this.visibleTodos = this.sortVisibleTodoList(filtered);
    this.syncVisibleTodoCards();
  }

  resolveCategoryName(categoryId: number): string {
    const resolvedId = this.normalizeId(categoryId);
    if (resolvedId <= 0) {
      return this.defaultCategoryName;
    }
    const found = this.categories.find(
      (item: TodoCategory) => this.normalizeId(item.id) === resolvedId,
    );
    return found ? found.category : this.defaultCategoryName;
  }

  resolveCategoryColor(categoryId: number): string {
    const resolvedId = this.normalizeId(categoryId);
    if (resolvedId <= 0) {
      const learning = this.categories.find(
        (item: TodoCategory) => item.category === this.defaultCategoryName,
      );
      return learning ? learning.color : this.getCategoryColorPalette()[0];
    }
    const found = this.categories.find(
      (item: TodoCategory) => this.normalizeId(item.id) === resolvedId,
    );
    return found ? found.color : this.getCategoryColorPalette()[0];
  }

  async createTodo(title: string, detail: string, categoryId: number): Promise<boolean> {
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
    todo.content = trimmedTitle;
    todo.detail = trimmedDetail;
    const defaultCategoryId = this.getDefaultCategoryId();
    const candidateId = this.normalizeId(categoryId);
    const hasCandidate =
      candidateId > 0 &&
      this.categories.some((item: TodoCategory) => this.normalizeId(item.id) === candidateId);
    const resolvedCategoryId = hasCandidate
      ? candidateId
      : defaultCategoryId > 0
        ? defaultCategoryId
        : this.categories.length > 0
          ? this.normalizeId(this.categories[0].id)
          : 0;
    if (resolvedCategoryId <= 0) {
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

  async updateTodoTitle(todoId: number, title: string): Promise<void> {
    const normalizedTodoId = this.normalizeId(todoId);
    if (normalizedTodoId <= 0) {
      return;
    }
    const nextTitle = this.safeTrim(title);
    const now = Date.now();
    let targetTodo: Todo | null = null;
    const hasLocalTodo = this.todos.some(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );

    const localIndex = this.todos.findIndex(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );
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
    if (!hasLocalTodo) {
      await this.refreshTodos();
    }
  }

  async updateTodoDetail(todoId: number, detail: string): Promise<void> {
    const normalizedTodoId = this.normalizeId(todoId);
    if (normalizedTodoId <= 0) {
      return;
    }
    const nextDetail = this.safeTrim(detail);
    const now = Date.now();
    let targetTodo: Todo | null = null;
    const hasLocalTodo = this.todos.some(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );

    const localIndex = this.todos.findIndex(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );
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
    if (!hasLocalTodo) {
      await this.refreshTodos();
    }
  }

  async updateTodoCategory(todoId: number, categoryId: number): Promise<void> {
    await this.ensureDefaultCategories();
    if (this.categories.length === 0) {
      await this.refreshCategories();
    }
    const normalizedTodoId = this.normalizeId(todoId);
    if (normalizedTodoId <= 0) {
      return;
    }
    this.clearPendingRestoreMove(normalizedTodoId);

    const candidateId = this.normalizeId(categoryId);
    const valid =
      candidateId > 0 &&
      this.categories.some((item: TodoCategory) => this.normalizeId(item.id) === candidateId);
    const fallbackCategoryId =
      this.getDefaultCategoryId() > 0
        ? this.getDefaultCategoryId()
        : this.categories.length > 0
          ? this.normalizeId(this.categories[0].id)
          : 0;
    const resolvedCategoryId = valid ? candidateId : fallbackCategoryId;
    if (resolvedCategoryId <= 0) {
      return;
    }

    const now = Date.now();
    let targetTodo: Todo | null = null;
    const hasLocalTodo = this.todos.some(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );

    const localIndex = this.todos.findIndex(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );
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
    if (!hasLocalTodo) {
      await this.refreshTodos();
    }
  }

  async toggleDone(todoId: number, isDone: boolean): Promise<void> {
    const normalizedTodoId = this.normalizeId(todoId);
    if (normalizedTodoId <= 0) {
      return;
    }
    const nextDone = isDone ? 1 : 0;
    const now = Date.now();
    let targetTodo: Todo | null = null;
    const hasLocalTodo = this.todos.some(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );

    const localIndex = this.todos.findIndex(
      (item: Todo) => this.normalizeId(item.id) === normalizedTodoId,
    );
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

  async updateCategoryName(categoryId: number, name: string): Promise<void> {
    const normalizedId = this.normalizeId(categoryId);
    const trimmed = this.safeTrim(name);
    if (normalizedId <= 0 || trimmed.length === 0) {
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

  async removeCategory(categoryId: number, cascadeDeleteTodos: boolean = false): Promise<boolean> {
    const normalizedId = this.normalizeId(categoryId);
    if (normalizedId <= 0) {
      return false;
    }
    await this.ensureDefaultCategories();
    if (this.categories.length === 0) {
      await this.refreshCategories();
    }

    const removing = this.categories.find(
      (item: TodoCategory) => this.normalizeId(item.id) === normalizedId,
    );
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
        if (this.normalizeId(todos[i].categoryId) === normalizedId) {
          await this.todoRepository.removeById(todos[i].id);
        }
      }
    } else {
      const fallbackCategoryId =
        this.getDefaultCategoryId() > 0
          ? this.getDefaultCategoryId()
          : this.categories.length > 0
            ? this.categories[0].id
            : 0;
      if (fallbackCategoryId > 0) {
        const todos = await this.todoRepository.findAll();
        for (let i = 0; i < todos.length; i++) {
          if (this.normalizeId(todos[i].categoryId) === normalizedId) {
            todos[i].categoryId = fallbackCategoryId;
            todos[i].updatedAt = Date.now();
            await this.todoRepository.save(todos[i]);
          }
        }
      }
    }
    await this.categoryRepository.removeById(normalizedId);
    if (this.selectedCategoryId === normalizedId) {
      this.selectedCategoryId = 0;
    }
    await this.refreshCategories();
    await this.refreshTodos();
    return true;
  }

  requestDeleteTodo(todoId: number): void {
    const normalizedId = this.normalizeId(todoId);
    if (normalizedId <= 0) {
      return;
    }
    this.clearPendingRestoreMove(normalizedId);
    const target = this.todos.find((item: Todo) => this.normalizeId(item.id) === normalizedId);

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
    this.undoTasks = [
      ...this.undoTasks,
      new TodoUndoTask(taskId, snapshot, originalIndex, timerId, deadlineMs),
    ];
    this.todos = this.todos.filter((item: Todo) => this.normalizeId(item.id) !== normalizedId);
    if (this.normalizeId(this.editingTodoId) === normalizedId) {
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
    const snapshotId = this.normalizeId(task.todo.id);
    const exists = this.todos.some((item: Todo) => this.normalizeId(item.id) === snapshotId);
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.todos.length));
      const before = this.todos.slice(0, insertIndex);
      const after = this.todos.slice(insertIndex);
      this.todos = [...before, task.todo, ...after];
      this.markTodoPendingRestoreMove(snapshotId);
    }
    this.syncVisibleTodos();
  }

  async commitDeleteTodo(taskId: string): Promise<void> {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    const todoId = this.normalizeId(task.todo.id);
    this.closeUndo(taskId);
    if (todoId <= 0) {
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
          `${title.length > 0 ? title : "待办"} 已删除`,
          "撤销",
          5000,
          task.deadlineMs,
        ),
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

  private hasUndoTaskForTodo(todoId: number): boolean {
    const normalizedId = this.normalizeId(todoId);
    return this.undoTasks.some(
      (task: TodoUndoTask) => this.normalizeId(task.todo.id) === normalizedId,
    );
  }

  isTodoPendingRestoreMove(todoId: number): boolean {
    const normalizedId = this.normalizeId(todoId);
    if (normalizedId <= 0) {
      return false;
    }
    return this.pendingRestoreMoveTodoIds.some((id: number) => this.normalizeId(id) === normalizedId);
  }

  settlePendingRestoreMove(todoId: number): void {
    const normalizedId = this.normalizeId(todoId);
    if (normalizedId <= 0) {
      return;
    }
    if (!this.isTodoPendingRestoreMove(normalizedId)) {
      return;
    }
    animateTo({ duration: 280, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
      this.clearPendingRestoreMove(normalizedId);
      this.syncVisibleTodos();
    });
  }

  private markTodoPendingRestoreMove(todoId: number): void {
    const normalizedId = this.normalizeId(todoId);
    if (normalizedId <= 0) {
      return;
    }

    const exists = this.pendingRestoreMoveTodoIds.some(
      (id: number) => this.normalizeId(id) === normalizedId,
    );
    if (!exists) {
      this.pendingRestoreMoveTodoIds = [...this.pendingRestoreMoveTodoIds, normalizedId];
    }
  }

  private clearPendingRestoreMove(todoId: number): void {
    const normalizedId = this.normalizeId(todoId);
    if (normalizedId <= 0) {
      return;
    }

    const next = this.pendingRestoreMoveTodoIds.filter(
      (id: number) => this.normalizeId(id) !== normalizedId,
    );
    if (next.length !== this.pendingRestoreMoveTodoIds.length) {
      this.pendingRestoreMoveTodoIds = next;
    }
  }

  private findTodoIndexById(todoId: number): number {
    for (let i = 0; i < this.todos.length; i++) {
      if (this.normalizeId(this.todos[i].id) === todoId) {
        return i;
      }
    }
    return this.todos.length;
  }

  private pickColorForNewCategory(): string {
    const index = this.categories.length;
    const colorPalette = this.getCategoryColorPalette();
    return colorPalette[index % colorPalette.length];
  }
}

const TODO_PAGE_STATE: TodoPageState = new TodoPageState();

export function useTodoPageState(): TodoPageState {
  return TODO_PAGE_STATE;
}
