import { QueryBuilder, getORM, Class } from '@ibestservices/ibest-orm';
import { BaseEntity } from '../models/BaseEntity';

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
  protected orm = getORM();
  protected entityClass: Class<T>;

  constructor(entityClass: Class<T>) {
    this.entityClass = entityClass;
  }

  get query(): QueryBuilder<T> {
    return this.orm.query(this.entityClass);
  }

  save(entity: T): Promise<void> {
    const id: string = entity.id;

    if (id.length === 0) {
      this.orm.insert<T>(entity);
      return Promise.resolve();
    }

    const existed: T | null = this.query.where('id', id).first();
    if (existed === null) {
      this.orm.insert<T>(entity);
    } else {
      this.orm.save<T>(entity);
    }
    return Promise.resolve();
  }

  removeById(id: string): Promise<void> {
    this.query.where('id', id).delete();
    return Promise.resolve();
  }

  findById(id: string): Promise<T | null> {
    return Promise.resolve(this.query.where('id', id).first());
  }

  findAll(): Promise<Array<T>> {
    return Promise.resolve(this.query.find());
  }
}
