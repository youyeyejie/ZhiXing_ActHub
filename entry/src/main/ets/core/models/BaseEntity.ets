/**
 * 类功能简介：
 * - 业务实体抽象基类，提供统一主键字段定义。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 为子实体提供共享的 `id` 字段约束。
 *
 * 副作用：
 * - 无副作用。
 */
export abstract class BaseEntity {
  id: number = 0;
}
