import { User } from '../models/User';
import { UserRepository } from '../repositories/UserRepository';

/**
 * 类功能简介：
 * - 本地认证服务，封装注册、登录与当前用户状态管理。
 *
 * 可传入项：
 * - `login/register` 需传入账号与密码。
 *
 * 返回行为：
 * - 返回登录/注册是否成功与当前登录用户信息。
 *
 * 副作用：
 * - 成功登录或注册时会更新 `currentUser` 状态。
 */
export class AuthService {
  private userRepository: UserRepository = new UserRepository();
  private currentUser: User | null = null;

  async login(account: string, password: string): Promise<boolean> {
    const user: User | null = await this.userRepository.login(account, password);
    this.currentUser = user;
    return user !== null;
  }

  async register(account: string, password: string): Promise<boolean> {
    const user: User | null = await this.userRepository.register(account, password);
    this.currentUser = user;
    return user !== null;
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  logout(): void {
    this.currentUser = null;
  }
}
