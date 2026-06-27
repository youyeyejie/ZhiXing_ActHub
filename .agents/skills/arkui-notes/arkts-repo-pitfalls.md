# ArkTS / Repo Pitfalls

记录本仓库里已经踩到的、容易按 TypeScript 习惯误写但 ArkTS 或当前三方库并不支持的点。

## ArkTS 语法限制

### 1. 不支持 constructor 参数属性声明

TypeScript 可写：

```ts
constructor(protected entityClass: Class<T>) {}
```

ArkTS 会报 `arkts-no-ctor-prop-decls`。

应改为：

```ts
protected entityClass: Class<T>;

constructor(entityClass: Class<T>) {
  this.entityClass = entityClass;
}
```

### 2. 不要用交叉类型补字段

TypeScript 常见写法：

```ts
const entityWithId = entity as Object & { id?: string | number };
```

ArkTS 会报：

- `arkts-no-intersection-types`
- `arkts-no-obj-literals-as-types`

在仓库里更稳妥的做法是把公共字段直接提到共享基类，例如把 `id` 声明到 `BaseEntity`，然后在泛型仓储里直接访问 `entity.id`。

### 3. 不要依赖内联对象类型声明

ArkTS 对 `{ id?: string }` 这种对象字面量类型位置更严格。仓库内如果需要复用结构，优先：

- 提取成命名 `class`
- 或提取成命名 `interface`
- 或直接放入已有基类/实体基类

不要在 `.ets` 里大量使用 TypeScript 风格的内联类型技巧。

## ArkUI / 状态更新认知

### 4. `@Local` 数组的 `push()` 会触发更新

这次测试页里最开始误以为要像 React 一样重新赋值数组，才会刷新 UI。

对当前仓库使用的 ArkUI V2 状态模型来说，`@Local private logs: string[] = [];` 上直接执行：

```ts
this.logs.push(message);
```

可以触发对应更新 hook，不需要为了刷新 UI 强行改成重新创建数组。

除非有截断、重排、去重等额外需求，否则保留原地 `push()` 更直接。

### 5. `@StorageProp` 不能直接用在 `@ComponentV2`

这次给 `SafeAreaInsetLayout` 做系统避让同步时，最开始按旧装饰器习惯写了：

```ts
@ComponentV2
export struct SafeAreaInsetLayout {
  @StorageProp('systemTopInsetPx') private systemTopInsetPx: number = 0;
}
```

ArkTS 会直接报错：

- `The '@StorageProp' decorator can only be used in a 'struct' decorated with '@Component'`

也就是说，这个装饰器不能直接套在当前仓库大量使用的 `@ComponentV2` 组件上。

在本仓库里如果只是读取全局存储，优先改成运行时显式读取，例如：

```ts
const value: number | undefined = AppStorage.get<number>('systemTopInsetPx');
```

不要先假设 V1 状态装饰器可以直接平移到 V2 组件。

### 6. `AppStorage.get()` 需要显式类型参数，否则容易踩 `arkts-no-any-unknown`

这次最开始直接写：

```ts
const value = AppStorage.get(key);
```

会被 ArkTS 推成弱类型，触发：

- `Use explicit types instead of "any", "unknown" (arkts-no-any-unknown)`

更稳妥的写法是：

```ts
const value: number | undefined = AppStorage.get<number>(key);
```

也就是：

- 给 `AppStorage.get<T>()` 显式泛型
- 给接收变量显式联合类型

不要把这类全局存储 API 当成 TypeScript 里可以后推断再缩窄的宽松接口。

### 7. `window` 避让区相关 API 需要按“可能抛错”处理

这次在 `EntryAbility` 里直接调用：

```ts
windowInstance.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
```

编译会提示：

- `Function may throw exceptions. Special handling is required.`

在仓库里处理窗口、安全区、系统栏这类 API 时，不能只看返回类型，还要默认它们是“受设备/窗口状态影响、可能抛错”的接口。

更安全的模式是：

```ts
try {
  const area = windowInstance.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
  // use area
} catch (_error) {
  // fallback
}
```

同理，监听回调里读取 `data.area` 也不要想当然认为永远安全。

### 8. `expandSafeArea()` 只扩展绘制，不会二次布局

这次处理标题栏和底部沉浸式时，最容易误判的一点是：`expandSafeArea()` 不会像 CSS padding 那样重新参与布局，它只扩展组件自己的绘制区域。

在当前仓库里意味着：

- 适合挂在“背景块”“头部条”“底栏背景”这类视觉容器上
- 不适合拿来替代真正的安全区布局或键盘避让逻辑
- 不要指望给整个页面根容器加了之后，子组件就自动获得正确的避让

尤其是软键盘场景里，如果把它挂在整页或错误层级上，很容易出现：

- 子组件仍然被顶动
- 顶部标题被一起推向状态栏
- 背景看起来对了，但布局还是错的

### 9. 滚动页面里的沉浸式和键盘避让不要混在同一层做

这次测试页就是典型例子：标题、说明、按钮和输入框全都塞在一个 `Scroll` 里时，软键盘避让会连同顶部内容一起参与滚动/压缩，容易出现“顶部溢出到状态栏”的错觉或真溢出。

对本仓库的页面结构，更稳的经验是：

- 顶部标题区单独抽成头部容器
- 头部如果要保持稳定，再只对这个头部容器做特殊处理
- 滚动内容和输入区留给系统默认键盘避让

不要把“测试键盘避让”“沉浸式背景扩展”“滚动内容”三件事都压进同一个 `Scroll` 根容器里处理。

### 10. 当前项目如果要测试“默认软键盘避让”，不要同时启用窗口全屏布局方案

`immersive-effects.md` 里的窗口全屏布局方案本身没错，但它适合“应用自己接管避让区”的场景。

而这次任务是测试“默认的软键盘避让方式”。如果同时做了：

- `setWindowLayoutFullScreen(true)`
- 自己计算状态栏/导航区 padding
- 再观察默认键盘避让

这三者很容易互相干扰，最后看到的行为不再是“默认避让”。

对本仓库当前阶段，更稳妥的做法是：

- 保持组件安全区方案
- 只把 `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP/BOTTOM])` 用在视觉背景块上
- 键盘避让仍交给系统默认行为

如果目标是“验证默认软键盘避让”，先不要混入窗口全屏布局实验。

## IBest-ORM 在本仓库里的注意点

### 11. 查询入口要走 `orm.query(EntityClass)`，不要只用 `orm.table(tableName)`

本仓库的实体都依赖 `@Table`、`@Column`、`@PrimaryKey` 元数据。

如果仓储层只写：

```ts
orm.table(tableName)
```

查询会绕开实体类元数据，容易导致：

- 主键字段映射不一致
- 查询结果无法稳定反序列化为实体
- `save()` 与 `findById()` 不走同一套实体信息

仓库里的 `BaseRepository` 应统一持有 `entityClass: Class<T>`，并通过：

```ts
this.orm.query(this.entityClass)
```

创建查询对象。

### 12. `save()` 不是严格意义上的 upsert，很多“写不进去/查不到”现象先看主键行为

从 `ibest-orm` 声明和实测行为看：

- `insert(entity)` 是显式插入
- `save(entity)` 更接近“按当前主键更新已有记录，否则按库自身规则处理”

不要想当然把 `save()` 当成“带手动字符串主键也能稳定 upsert”的接口。

这次仓库里出现过的几类误解，其实很多都不是 `save()` 本身的锅，而是先被“主键默认自增 / 主键被 ORM 回写”放大了：

- 以为字符串主键能天然当作稳定业务 ID
- 以为 `save()` 会严格按手动字符串主键做 upsert
- 以为单例行查不到是因为没 migrate

当前仓库默认策略也已经统一到：

- 业务实体主键默认使用 `number` 自增主键
- 不再手动生成随机字符串 `id`

基类仓储目前采用的安全策略是：

1. `id` 为空时直接 `insert`
2. `id` 非空时先查存在性
3. 不存在则 `insert`
4. 存在才 `save`

这套策略本身没有问题，但前提是：

- 主键定义符合 ORM 预期
- 插入后实体主键不会和预期脱钩

否则“先查存在性再 save”的判断基准本身就不可靠。

### 13. 字符串主键如果出现异常，先检查并改成 `@PrimaryKey({ autoIncrement: false })`

本仓库里如果字符串主键相关行为出现异常，例如：

- 插入后实体 `id` 被改写
- 按原字符串 `id` 查询不到
- `save()` / 登录态 / 单例行表现不稳定

不要先怀疑查询、`save()` 或 `migrate`，先检查主键定义。

不要直接写：

```ts
@PrimaryKey()
id: string = ''
```

默认直接假设应改成：

```ts
@PrimaryKey({ autoIncrement: false })
id: string = ''
```

这次 `User`、`Plan`、`Todo`、`Idea`、`Focus`、`TodoCategory`、`UserPreference` 都需要按这个规则处理。

另外，像登录态、schema 版本、全局配置这种应用级单例状态，也优先用 key/value 表，不要先做字符串主键单例实体。
- 取“最新一条”时被错误的空行覆盖

对这类少量全局配置，更稳的方式是单独做 key/value 表，例如：

- `schema.version`
- `session.logged_in`
- `session.username`

所以仓库内的经验结论压缩成一句话就是：

- 业务实体若坚持用字符串主键，必须显式 `autoIncrement: false`
- 应用级单例配置优先 key/value 表，不要先做字符串主键单例实体

### 14. `build()` 方法里不要写独立副作用语句

这次重构页面时，在 `build()` 开头写了普通函数调用：

```ts
build() {
  this.syncBottomBarVisibility();
  Stack() { ... }
}
```

ArkTS 编译器会报类似：

- `In an '@Entry' decorated component, the 'build' method can have only one root node...`
- 以及伴随的 `Unexpected token`（定位在文件末尾附近）

根因是 `build()` 里出现了 UI 树之外的独立语句，破坏了“单根 UI 描述”约束。

更稳妥的做法：

- 把状态同步放到事件回调、生命周期（`aboutToAppear/aboutToDisappear`）或明确的业务方法里
- `build()` 里只保留声明式 UI 结构与条件渲染

如果出现“看起来像语法错、但实际是 build 结构错”的报错组合，优先检查这里。

### 15. `NavDestinationMode.DIALOG` 承载 ActionSheet 时，遮罩不一定覆盖状态栏区域

这次把 ActionSheet 统一迁移到 `this.app.nav.openActionSheet(...)` 后，发现专注页打开任务选择面板时，屏幕顶部会残留一条未被遮罩的区域。

根因是：`NavDestination` 处于 `DIALOG` 模式时，默认安全区绘制范围可能不覆盖状态栏区域；而 ActionSheet 的 mask 是按目的页可绘制区域铺满。

在本仓库的稳定修正是给 overlay 目的页补上：

```ts
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
```

适用位置：`components/overlays/ActionSheetOverlayDestination.ets`。

如果后续出现“底部/顶部半透明遮罩缺口”，优先检查 overlay 目的页是否扩展了系统安全区。

### 18. 图标保存按钮要优先用同一节点的 `.enabled(...)`，不要只靠 `onClick` 内部 `if (!enabled) return`

这次在 `plan/todo/idea` 的编辑表单里复现到：

- 文本按钮版本使用 `.enabled(表达式)`，可用态和按钮样式刷新稳定
- 图标按钮版本如果仅靠 `onClick` 里拦截，视觉上容易出现“看起来没禁用/没变色”的错觉

在本仓库更稳的写法是：

```ts
Button({ type: ButtonType.Circle, stateEffect: true }) {
  SymbolGlyph(icon)
}
  .backgroundColor(enabled ? palette.primary : palette.border)
  .opacity(enabled ? 1 : 0.56)
  .enabled(enabled)
```

结论：

- 保存按钮是否可点，交给 `.enabled(...)` 做一等约束
- 颜色、透明度跟同一个 `enabled` 变量绑定
- `onClick` 里的守卫可保留，但不能替代 `.enabled(...)`

### 17. `ForEach` 的 key 不要绑定会频繁变化的字段（如 `updatedAt`）

这次待办列表重构里，卡片 key 最开始写成：

```ts
(item: Todo) => `${item.id}_${item.updatedAt}`
```

当勾选完成态、改分类或编辑内容时，`updatedAt` 会变化，导致 ArkUI 把同一条数据识别成“新节点”，出现：

- 卡片重建而不是平滑位置移动
- 列表看起来像闪现/闪屏
- 原本期望的补位动画被打断

在本仓库里更稳妥的做法：

- 优先使用稳定且唯一的业务主键作为 key（如 `item.id`）
- 只有在主键缺失时再用创建时固定字段兜底
- 不要把时间戳、选中态、过滤态等“会变化”的字段拼进 key

### 19. `@kit.ArkTSUtils` 不存在，ArrayBuffer/Uint8Array 转字符串用 `buffer` from `@kit.ArkTS`

当前 SDK（compatibleSdkVersion 6.0.2 / API 22）没有 `@kit.ArkTSUtils` 模块。编译会报：

- `Cannot find module '@kit.ArkTSUtils'`
- `Kit '@kit.ArkTSUtils' has no corresponding config file in ArkTS SDK`

如果需要将 `ArrayBuffer` 或 `Uint8Array` 解码为字符串，不要用 `util.TextDecoder`（它属于不存在的 `@kit.ArkTSUtils`）。

正确做法是从 `@kit.ArkTS` 导入 `buffer`：

```ts
import { buffer } from "@kit.ArkTS";

// ArrayBuffer → string
const text: string = buffer.from(arrayBuffer).toString('utf-8');

// Uint8Array → string
const text2: string = buffer.from(uint8Array).toString('utf-8');
```

本仓库中 `IcsService.ets`、`HashUtils.ets` 都已使用此模式。
