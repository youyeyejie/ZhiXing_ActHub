import { Focus } from '../models/Focus';
import { Idea } from '../models/Idea';
import { Plan } from '../models/Plan';
import { Todo } from '../models/Todo';
import { TodoCategory } from '../models/TodoCategory';
import { User } from '../models/User';
import { FocusRepository } from '../repositories/FocusRepository';
import { IdeaRepository } from '../repositories/IdeaRepository';
import { PlanRepository } from '../repositories/PlanRepository';
import { TodoRepository } from '../repositories/TodoRepository';
import { TodoCategoryRepository } from '../repositories/TodoCategoryRepository';
import { UserRepository } from '../repositories/UserRepository';

export enum SearchScope {
  Plan = 'plan',
  Todo = 'todo',
  Idea = 'idea',
  Focus = 'focus',
  User = 'user'
}

/**
 * 类功能简介：
 * - 统一搜索结果数据结构。
 *
 * 可传入项：
 * - 通过实例字段赋值写入 id、title、subtitle 和 scope。
 *
 * 返回行为：
 * - 作为搜索结果 DTO 在页面层渲染。
 *
 * 副作用：
 * - 无副作用（数据承载类）。
 */
export class SearchResultItem {
  id: number = 0;
  title: string = '';
  subtitle: string = '';
  timeText: string = '';
  locationText: string = '';
  categoryText: string = '';
  statusText: string = '';
  descriptionText: string = '';
  scope: SearchScope = SearchScope.Plan;
}

/**
 * 类功能简介：
 * - 统一搜索服务，按模块范围查询本地仓储并返回标准结果。
 *
 * 可传入项：
 * - `search(scope, keyword)` 传入搜索范围与关键字。
 *
 * 返回行为：
 * - 返回匹配项列表，关键字为空时返回空数组。
 *
 * 副作用：
 * - 会访问各模块仓储执行读查询。
 */
export class SearchService {
  private planRepository: PlanRepository = new PlanRepository();
  private todoRepository: TodoRepository = new TodoRepository();
  private todoCategoryRepository: TodoCategoryRepository = new TodoCategoryRepository();
  private ideaRepository: IdeaRepository = new IdeaRepository();
  private focusRepository: FocusRepository = new FocusRepository();
  private userRepository: UserRepository = new UserRepository();

  async search(scope: SearchScope, keyword: string): Promise<Array<SearchResultItem>> {
    const normalized: string = keyword.trim().toLowerCase();
    if (normalized.length === 0) {
      return Promise.resolve([]);
    }

    switch (scope) {
      case SearchScope.Plan:
        return this.searchPlans(normalized);
      case SearchScope.Todo:
        return this.searchTodos(normalized);
      case SearchScope.Idea:
        return this.searchIdeas(normalized);
      case SearchScope.Focus:
        return this.searchFocus(normalized);
      case SearchScope.User:
        return this.searchUsers(normalized);
      default:
        return Promise.resolve([]);
    }
  }

  private async searchPlans(keyword: string): Promise<Array<SearchResultItem>> {
    const plans: Array<Plan> = await this.planRepository.findAll();
    const results: Array<SearchResultItem> = [];
    plans.forEach((item: Plan) => {
      const title = this.normalizeText(item.content);
      const timeText = this.resolvePlanTimeText(item);
      const location = this.normalizeText(item.location);
      const description = this.normalizeText(item.description);
      const haystack = `${title} ${timeText} ${location} ${description}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        const result = this.createItem(item.id, title, this.joinDisplayParts(timeText, location), SearchScope.Plan);
        result.timeText = timeText;
        result.locationText = location;
        result.descriptionText = description;
        results.push(result);
      }
    });
    return results;
  }

  private async searchTodos(keyword: string): Promise<Array<SearchResultItem>> {
    const todos: Array<Todo> = await this.todoRepository.findAll();
    const categories: Array<TodoCategory> = await this.todoCategoryRepository.findAll();
    const results: Array<SearchResultItem> = [];
    todos.forEach((item: Todo) => {
      const title = this.normalizeText(item.content);
      const detail = this.normalizeText(item.detail);
      const categoryName = this.resolveTodoCategoryName(categories, item.categoryId);
      const state = item.isDone === 1 ? '已完成' : '进行中';
      const haystack = `${title} ${detail} ${categoryName} ${state}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        const result = this.createItem(item.id, title, this.joinDisplayParts(categoryName, state), SearchScope.Todo);
        result.categoryText = categoryName;
        result.statusText = state;
        result.descriptionText = detail;
        results.push(result);
      }
    });
    return results;
  }

  private async searchIdeas(keyword: string): Promise<Array<SearchResultItem>> {
    const ideas: Array<Idea> = await this.ideaRepository.findAll();
    const results: Array<SearchResultItem> = [];
    ideas.forEach((item: Idea) => {
      const title = this.normalizeText(item.title);
      const resolvedTitle = title.length > 0 ? title : '未命名闪记';
      const content = this.normalizeText(item.content);
      const haystack = `${resolvedTitle} ${content}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        const result = this.createItem(item.id, resolvedTitle, content, SearchScope.Idea);
        result.descriptionText = content;
        results.push(result);
      }
    });
    return results;
  }

  private async searchFocus(keyword: string): Promise<Array<SearchResultItem>> {
    const focuses: Array<Focus> = await this.focusRepository.findAll();
    const results: Array<SearchResultItem> = [];
    focuses.forEach((item: Focus) => {
      const title = `专注 ${item.duration} 分钟`;
      const subtitle = `待办ID: ${item.todoId}`;
      const haystack = `${title} ${subtitle}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        results.push(this.createItem(item.id, title, subtitle, SearchScope.Focus));
      }
    });
    return results;
  }

  private async searchUsers(keyword: string): Promise<Array<SearchResultItem>> {
    const users: Array<User> = await this.userRepository.findAll();
    const results: Array<SearchResultItem> = [];
    users.forEach((item: User) => {
      const haystack = `${item.name}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        results.push(this.createItem(item.id, item.name, '用户账号', SearchScope.User));
      }
    });
    return results;
  }

  private normalizeText(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours();
    const minute = date.getMinutes();
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  private formatMonthDay(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getMonth() + 1}/${date.getDate()}`;
  }

  private isSameDay(startTime: number, endTime: number): boolean {
    const startDate = new Date(startTime);
    const endDate = new Date(endTime);
    return startDate.getFullYear() === endDate.getFullYear() &&
      startDate.getMonth() === endDate.getMonth() &&
      startDate.getDate() === endDate.getDate();
  }

  private resolvePlanTimeText(plan: Plan): string {
    const startTime = plan.startTime > 0 ? plan.startTime : plan.timestamp;
    const endTime = plan.endTime > 0 ? plan.endTime : startTime;
    if (startTime <= 0) {
      return '';
    }
    if (endTime <= startTime) {
      return `${this.formatMonthDay(startTime)} ${this.formatHourMinute(startTime)}`;
    }
    if (!this.isSameDay(startTime, endTime)) {
      return `${this.formatMonthDay(startTime)} ${this.formatHourMinute(startTime)} - ${this.formatMonthDay(endTime)} ${this.formatHourMinute(endTime)}`;
    }
    return `${this.formatHourMinute(startTime)} - ${this.formatHourMinute(endTime)}`;
  }

  private joinDisplayParts(first: string, second: string): string {
    const parts: Array<string> = [];
    const firstPart = this.normalizeText(first);
    const secondPart = this.normalizeText(second);
    if (firstPart.length > 0) {
      parts.push(firstPart);
    }
    if (secondPart.length > 0) {
      parts.push(secondPart);
    }
    return parts.join(' · ');
  }

  private resolveTodoCategoryName(categories: Array<TodoCategory>, categoryId: number): string {
    const resolvedId = categoryId > 0 ? categoryId : 0;
    if (resolvedId <= 0) {
      return '';
    }
    const found = categories.find((item: TodoCategory) => item.id === resolvedId);
    if (!found) {
      return '';
    }
    return this.normalizeText(found.category);
  }

  private createItem(id: number, title: string, subtitle: string, scope: SearchScope): SearchResultItem {
    const item: SearchResultItem = new SearchResultItem();
    item.id = id;
    item.title = title;
    item.subtitle = subtitle;
    item.scope = scope;
    return item;
  }
}
