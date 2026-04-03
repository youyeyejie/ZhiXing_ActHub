import { User } from '../models/User';
import { UserRepository } from '../repositories/UserRepository';

/**
 * 本地认证服务。
 * 当前版本仅使用本地数据库完成注册与登录，不接入远端后端。
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
