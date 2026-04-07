/**
 * 业务实体抽象基类。
 * 当前仅作为仓储层的统一类型边界，避免在 ORM 元数据层依赖继承展开。
 * 各实体会显式声明自身字段，确保 @ibestservices/ibest-orm 可以稳定收集列定义。
 */
export abstract class BaseEntity {
  id: string = '';
}
