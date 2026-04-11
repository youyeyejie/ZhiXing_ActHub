import { Focus } from '../models/Focus';
import { Idea } from '../models/Idea';
import { Plan } from '../models/Plan';
import { Todo } from '../models/Todo';
import { User } from '../models/User';
import { FocusRepository } from '../repositories/FocusRepository';
import { IdeaRepository } from '../repositories/IdeaRepository';
import { PlanRepository } from '../repositories/PlanRepository';
import { TodoRepository } from '../repositories/TodoRepository';
import { UserRepository } from '../repositories/UserRepository';

export enum SearchScope {
  Plan = 'plan',
  Todo = 'todo',
  Idea = 'idea',
  Focus = 'focus',
  User = 'user'
}

export class SearchResultItem {
  id: string = '';
  title: string = '';
  subtitle: string = '';
  scope: SearchScope = SearchScope.Plan;
}

/**
 * 统一搜索服务。
 * 按页面类别查询本地仓储，并返回统一结果结构。
 */
export class SearchService {
  private planRepository: PlanRepository = new PlanRepository();
  private todoRepository: TodoRepository = new TodoRepository();
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
      const haystack = `${item.content} ${item.location} ${item.description}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        results.push(this.createItem(item.id, item.content, item.location, SearchScope.Plan));
      }
    });
    return results;
  }

  private async searchTodos(keyword: string): Promise<Array<SearchResultItem>> {
    const todos: Array<Todo> = await this.todoRepository.findAll();
    const results: Array<SearchResultItem> = [];
    todos.forEach((item: Todo) => {
      const titleText = `${item.content}`.trim();
      const title = titleText === 'undefined' || titleText === 'null' ? '' : titleText;
      const detailText = `${item.detail}`.trim();
      const detail = detailText === 'undefined' || detailText === 'null' ? '' : detailText;
      const haystack = `${title} ${detail} ${item.categoryId}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        const state = item.isDone === 1 ? '已完成' : '进行中';
        const subtitle = detail.length > 0 ? detail : state;
        results.push(this.createItem(item.id, title.length > 0 ? title : '未命名待办', subtitle, SearchScope.Todo));
      }
    });
    return results;
  }

  private async searchIdeas(keyword: string): Promise<Array<SearchResultItem>> {
    const ideas: Array<Idea> = await this.ideaRepository.findAll();
    const results: Array<SearchResultItem> = [];
    ideas.forEach((item: Idea) => {
      const haystack = `${item.title} ${item.content}`.toLowerCase();
      if (haystack.indexOf(keyword) >= 0) {
        results.push(this.createItem(item.id, item.title.length > 0 ? item.title : '未命名闪记', item.content, SearchScope.Idea));
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

  private createItem(id: string, title: string, subtitle: string, scope: SearchScope): SearchResultItem {
    const item: SearchResultItem = new SearchResultItem();
    item.id = id;
    item.title = title;
    item.subtitle = subtitle;
    item.scope = scope;
    return item;
  }
}
