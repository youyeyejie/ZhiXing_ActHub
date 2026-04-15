import { User } from '../models/User';
import { UserRepository } from '../repositories/UserRepository';

export class AuthService {
  private currentUser: User | null = null;

  private get userRepository(): UserRepository {
    return new UserRepository();
  }

  async login(account: string, password: string): Promise<User | null> {
    const user: User | null = await this.userRepository.login(account, password);
    this.currentUser = user;
    return user;
  }

  async register(account: string, password: string): Promise<User | null> {
    const user: User | null = await this.userRepository.register(account, password);
    this.currentUser = user;
    return user;
  }

  async restoreSession(userId: string): Promise<User | null> {
    const normalizedId: string = `${userId}`.trim();
    if (normalizedId.length === 0) {
      this.currentUser = null;
      return null;
    }

    const user: User | null = await this.userRepository.findById(normalizedId);
    this.currentUser = user;
    return user;
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  logout(): void {
    this.currentUser = null;
  }
}
