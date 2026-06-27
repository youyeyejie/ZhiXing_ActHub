---
name: arkui-notes
description: Best-practice notes for ArkUI and ArkTS page or component authoring in this repository. Use when Codex is writing, refactoring, or reviewing ArkUI code and would benefit from loading focused implementation notes on demand instead of relying only on generic knowledge. Also use when the user says a note was added or updated, so the note files can be reread and the index in this skill can be refreshed.
---

# ArkUI Notes

Use this skill as a lightweight note index for ArkUI coding work.

Do not load every note file by default. First identify the specific ArkUI topic involved in the task, then read only the relevant indexed note files.

## Workflow

1. Confirm the current task is about ArkUI or ArkTS UI authoring, refactoring, or review.
2. Scan the index below and open only the note files that match the topic.
3. Extract concrete guidance from the selected notes and apply it to the target code.
4. Keep generated code aligned with ArkTS constraints and the repository's module boundaries.

## Update Rule

When the user says a note was added, changed, or updated:

1. Read the changed note file instead of assuming the old summary is still correct.
2. Update the index in this `SKILL.md` so the file list and summary stay in sync with the actual notes on disk.
3. If the changed file is `arkts-repo-pitfalls.md`, also update the `Pitfalls` section title index in this `SKILL.md`.

## Index

- `quick-start.md`
  - ArkUI / ArkTS 基本语法、声明式 UI、属性链式调用、事件与箭头函数使用约束。
- `arkts-repo-pitfalls.md`
  - 本仓库已踩到的 ArkTS 与 TypeScript 语法差异、`@ComponentV2`/`AppStorage`/窗口与安全区 API 限制、键盘避让与沉浸式布局坑点，以及 IBest-ORM 在仓储层的实际行为。
- `state/index.md`
  - ArkTS V2 状态管理总览，适合先建立整体心智模型。
- `state/application.md`
  - AppStorageV2、PersistenceV2、应用级状态与持久化注意事项。
- `state/component.md`
  - 组件级状态装饰器、`@Provider/@Consumer` 等组件通信能力。
- `state/data-object.md`
  - `@ObservedV2`、`@Trace`、数据对象和计算属性相关约束。
- `state/mvvm-v2.md`
  - MVVM V2 更完整的状态建模与 UI 响应式写法。
- `state/utils.md`
  - 状态工具与辅助能力补充说明。

## Pitfalls

- `arkts-repo-pitfalls.md`
  - `ArkTS 语法限制`
  - `1. 不支持 constructor 参数属性声明`
  - `2. 不要用交叉类型补字段`
  - `3. 不要依赖内联对象类型声明`
  - `ArkUI / 状态更新认知`
  - `4. @Local 数组的 push() 会触发更新`
  - `5. @StorageProp 不能直接用在 @ComponentV2`
  - `6. AppStorage.get() 需要显式类型参数，否则容易踩 arkts-no-any-unknown`
  - `7. window 避让区相关 API 需要按“可能抛错”处理`
  - `8. expandSafeArea() 只扩展绘制，不会二次布局`
  - `9. 滚动页面里的沉浸式和键盘避让不要混在同一层做`
  - `10. 当前项目如果要测试“默认软键盘避让”，不要同时启用窗口全屏布局方案`
  - `IBest-ORM 在本仓库里的注意点`
  - `11. 查询入口要走 orm.query(EntityClass)，不要只用 orm.table(tableName)`
  - `12. save() 不是严格意义上的 upsert，很多“写不进去/查不到”现象先看主键行为`
  - `13. 字符串主键如果出现异常，先检查并改成 @PrimaryKey({ autoIncrement: false })`
  - `14. build() 方法里不要写独立副作用语句`
  - `15. NavDestinationMode.DIALOG 承载 ActionSheet 时，遮罩不一定覆盖状态栏区域`
  - `16. ForEach 的 key 不要绑定会频繁变化的字段（如 updatedAt）`
  - `SDK / Kit 模块`
  - `19. @kit.ArkTSUtils 不存在，ArrayBuffer/Uint8Array 转字符串用 buffer from @kit.ArkTS`
