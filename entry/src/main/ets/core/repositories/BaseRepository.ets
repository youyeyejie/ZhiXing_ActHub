import { QueryBuilder, Class, ORM } from "@ibestservices/ibest-orm";
import { BaseEntity } from "../models/BaseEntity";
import { RepositoryScope } from "../database/RepositoryScope";
import { AppDatabase } from "../database/AppDatabase";
import { UserDatabase } from "../database/UserDatabase";

/**
 * 类功能简介：
 * - 通用仓储基类，封装 IBest-ORM 的基础 CRUD 能力。
 *
 * 可传入项：
 * - 构造参数 `entityClass`：当前仓储对应的实体类型。
 *
 * 返回行为：
 * - 提供 `save/removeById/findById/findAll` 与 `query` 访问能力。
 *
 * 副作用：
 * - `save/removeById` 会直接写入或删除数据库记录。
 */
export abstract class BaseRepository<T extends BaseEntity> {
  protected entityClass: Class<T>;
  protected scope: RepositoryScope;

  constructor(entityClass: Class<T>, scope: RepositoryScope = RepositoryScope.USER) {
    this.entityClass = entityClass;
    this.scope = scope;
  }

  protected get orm(): ORM {
    if (this.scope === RepositoryScope.APP) {
      return AppDatabase.getInstance().getOrm();
    }
    return UserDatabase.getInstance().getOrm();
  }

  get query(): QueryBuilder<T> {
    return this.orm.query(this.entityClass);
  }

  insert(entity: T): Promise<boolean> {
    try {
      this.orm.insert<T>(entity);
      return Promise.resolve(true);
    } catch {
      return Promise.resolve(false);
    }
  }

  save(entity: T): Promise<void> {
    const id: number = entity.id;

    if (id <= 0) {
      this.orm.insert<T>(entity);
      return Promise.resolve();
    }

    const existed: T | null = this.query.where("id", id).first();
    if (existed === null) {
      this.orm.insert<T>(entity);
    } else {
      this.orm.save<T>(entity);
    }
    return Promise.resolve();
  }

  removeById(id: number): Promise<void> {
    this.query.where("id", id).delete();
    return Promise.resolve();
  }

  findById(id: number): Promise<T | null> {
    return Promise.resolve(this.query.where("id", id).first());
  }

  findAll(): Promise<Array<T>> {
    return Promise.resolve(this.query.find());
  }
}
