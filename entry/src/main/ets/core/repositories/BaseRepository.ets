import { Class, QueryBuilder, getORM } from '@ibestservices/ibest-orm';
import { BaseEntity } from '../models/BaseEntity';

// 定义 id 字段访问接口
interface Identifiable {
  id?: string;
}

// 使用 Object 替代 ESObject
interface QueryWithInsert {
  insert(data: Object): number;
}

interface QueryWithUpdate {
  update(data: Object): number;
}

interface OrmWithInsert {
  insert(entity: Object | Array<Object>): number;
}

interface OrmWithSave {
  save(entity: Object): number;
}

export abstract class BaseRepository<T extends BaseEntity> {
  private entityClass: Class<T>;

  constructor(entityClass: Class<T>) {
    this.entityClass = entityClass;
  }

  get query(): QueryBuilder<T> {
    // getORM().query 返回类型与 QueryBuilder<T> 可能不完全匹配，通过 Object 过渡断言
    return getORM().query(this.entityClass) as Object as QueryBuilder<T>;
  }

  save(entity: T): Promise<void> {
    try {
      const orm = getORM() as Object as OrmWithSave;
      if (orm && typeof orm.save === 'function') {
        // T 继承自 BaseEntity，BaseEntity 是类，可直接断言为 Object
        orm.save(entity as Object);
        return Promise.resolve();
      }
    } catch (_error) {
      // 静默回退
    }

    try {
      const identifiable = entity as Object as Identifiable;
      const id = identifiable.id;
      if (id) {
        const query = this.query.where('id', id) as Object as QueryWithUpdate;
        if (query && typeof query.update === 'function') {
          query.update(entity as Object);
        }
      }
    } catch (_error) {
      // 静默回退
    }
    return Promise.resolve();
  }

  async insert(entity: T): Promise<boolean> {
    try {
      const orm = getORM() as Object as OrmWithInsert;
      if (orm && typeof orm.insert === 'function') {
        const affected = orm.insert(entity as Object);
        return Promise.resolve(affected > 0);
      }
    } catch (_error) {
      // 静默回退
    }

    try {
      const query = this.query as Object as QueryWithInsert;
      if (query && typeof query.insert === 'function') {
        const affected = query.insert(entity as Object);
        return Promise.resolve(affected > 0);
      }
    } catch (_error) {
      // 静默回退
    }

    return Promise.resolve(false);
  }

  removeById(id: string): Promise<void> {
    try {
      this.query.where('id', id).delete();
    } catch (_error) {
      // 静默失败
    }
    return Promise.resolve();
  }

  findById(id: string): Promise<T | null> {
    try {
      const result = this.query.where('id', id).first() as Object as T | null;
      return Promise.resolve(result);
    } catch (_error) {
      return Promise.resolve(null);
    }
  }

  findAll(): Promise<Array<T>> {
    try {
      const result = this.query.find() as Object as Array<T>;
      return Promise.resolve(result);
    } catch (_error) {
      return Promise.resolve([]);
    }
  }
}