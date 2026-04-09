import { User } from '../models/User';
import { BaseRepository } from './BaseRepository';

/**
 * 用户仓储。
 * 使用本地数据库完成账号注册、登录校验和用户查询。
 */
export class UserRepository extends BaseRepository<User> {
  constructor() {
    super(User);
  }

  findByAccount(account: string): Promise<User | null> {
    return Promise.resolve(
      this.query.where('name', account).first()
    );
  }

  hasAccount(account: string): Promise<boolean> {
    return Promise.resolve(
      this.query.where('name', account).exists()
    );
  }

  register(account: string, password: string, avatar: string = ''): Promise<User | null> {
    const normalizedAccount: string = account.trim();
    const normalizedPassword: string = password.trim();
    if (normalizedAccount.length === 0 || normalizedPassword.length === 0) {
      return Promise.resolve(null);
    }

    if (this.query.where('name', normalizedAccount).exists()) {
      return Promise.resolve(null);
    }

    const now: number = Date.now();
    const user: User = new User();
    user.id = this.createUserId(normalizedAccount, now);
    user.name = normalizedAccount;
    user.avatar = avatar;
    user.password = normalizedPassword;
    user.timestamp = now;
    user.createdAt = now;
    user.updatedAt = now;

    return this.save(user).then(() => user);
  }

  login(account: string, password: string): Promise<User | null> {
    const normalizedAccount: string = account.trim();
    const normalizedPassword: string = password.trim();
    if (normalizedAccount.length === 0 || normalizedPassword.length === 0) {
      return Promise.resolve(null);
    }

    const user: User | null = this.query
      .where('name', normalizedAccount)
      .where('password', normalizedPassword)
      .first();
    if (user === null) {
      return Promise.resolve(null);
    }

    user.updatedAt = Date.now();
    return this.save(user).then(() => user);
  }

  updateProfile(user: User): Promise<void> {
    user.updatedAt = Date.now();
    return this.save(user);
  }

  private createUserId(account: string, timestamp: number): string {
    return `${account}_${timestamp}`;
  }
}
