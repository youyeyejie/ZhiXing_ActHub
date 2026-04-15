import { User } from "../models/User";
import { BaseRepository } from "./BaseRepository";
import { RepositoryScope } from "../database/RepositoryScope";

/**
 * 类功能简介：
 * - 用户仓储实现，封装本地注册、登录与用户资料更新能力。
 *
 * 可传入项：
 * - 方法入参包括账号、密码、头像与用户实体对象。
 *
 * 返回行为：
 * - 返回用户查询结果、注册/登录结果与更新执行结果。
 *
 * 副作用：
 * - 注册、登录、更新会写入数据库并更新时间戳。
 */
export class UserRepository extends BaseRepository<User> {
  constructor() {
    super(User, RepositoryScope.APP);
  }

  findByAccount(account: string): Promise<User | null> {
    return Promise.resolve(this.query.where("name", account).first());
  }

  hasAccount(account: string): Promise<boolean> {
    return Promise.resolve(this.query.where("name", account).exists());
  }

  register(account: string, password: string, avatar: string = ""): Promise<User | null> {
    const normalizedAccount: string = account.trim();
    const normalizedPassword: string = password.trim();
    if (normalizedAccount.length === 0 || normalizedPassword.length === 0) {
      return Promise.resolve(null);
    }

    if (this.query.where("name", normalizedAccount).exists()) {
      return Promise.resolve(null);
    }

    const now: number = Date.now();
    const user: User = new User();
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
      .where("name", normalizedAccount)
      .where("password", normalizedPassword)
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
}
