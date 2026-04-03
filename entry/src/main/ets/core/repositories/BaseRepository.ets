import { Class, getORM } from '@ibestservices/ibest-orm';
import { BaseEntity } from '../models/BaseEntity';

/**
 * 通用仓储基类。
 * 当前阶段提供基于 IBest-ORM 的最小 CRUD 能力，支撑各模块逐步落地。
 */
export abstract class BaseRepository<T extends BaseEntity> {
  protected tableName: string = '';
  protected entityClass: Class<T>;

  constructor(tableName: string, entityClass: Class<T>) {
    this.tableName = tableName;
    this.entityClass = entityClass;
  }

  save(entity: T): Promise<void> {
    getORM().save<T>(entity);
    return Promise.resolve();
  }

  removeById(id: string): Promise<void> {
    getORM().query(this.entityClass).where('id', id).delete();
    return Promise.resolve();
  }

  findById(id: string): Promise<T | null> {
    return Promise.resolve(getORM().query(this.entityClass).where('id', id).first());
  }

  findAll(): Promise<Array<T>> {
    return Promise.resolve(getORM().query(this.entityClass).find());
  }
}
