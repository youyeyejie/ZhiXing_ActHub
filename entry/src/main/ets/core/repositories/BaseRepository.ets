import { QueryBuilder, getORM, Class } from '@ibestservices/ibest-orm';
import { BaseEntity } from '../models/BaseEntity';

/**
 * 通用仓储基类。
 * 当前阶段提供基于 IBest-ORM 的最小 CRUD 能力，支撑各模块逐步落地。
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
