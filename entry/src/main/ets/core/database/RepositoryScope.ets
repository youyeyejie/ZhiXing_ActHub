/**
 * 组件功能简介：
 * - 仓储作用域枚举，用于标识查询走应用库或用户库。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 提供 `APP` 与 `USER` 两种作用域标识。
 *
 * 副作用：
 * - 无。
 */
export enum RepositoryScope {
  APP = 'APP',
  USER = 'USER'
}
