# 辅助接口

本页工具需要 `import { UIUtils } from '@kit.ArkUI';`

## getTarget

为了获取状态管理框架代理前的原始对象，开发者可以使用getTarget接口。

状态管理框架会对class、Date、Map、Set、Array类型的原始对象添加代理，用于观测属性变化与API调用。这一层代理会使得变量类型改变，在类型判断、NAPI调用等场景，会由于类型并非原始对象的类型产生预料之外的结果。

- getTarget仅支持对象类型传参。
- 更改getTarget获取的原始对象中的内容不会被观察到变化，也不会触发UI刷新。

```ts
import { UIUtils } from '@kit.ArkUI';
@Observed
class Info {
  public name: string = 'Tom';
}
@Entry
@Component
struct GetTargetObject {
  @State info: Info = new Info();

  build() {
    Column() {
      Text(`info.name: ${this.info.name}`)
      Button('Change Proxy Object Properties')
        .onClick(() => {
          this.info.name = 'Alice'; // Text组件能够刷新
        })
      Button('Change Original Object Properties')
        .onClick(() => {
          let rawInfo: Info = UIUtils.getTarget(this.info);
          rawInfo.name = 'Bob'; // Text组件不能刷新
        })
    }
  }
}
```

## makeObserved接口



状态管理框架已提供@ObservedV2/@Trace用于观察类属性变化，makeObserved接口提供主要应用于@ObservedV2/@Trace无法涵盖的场景：
- class的定义在三方包中：开发者无法手动对class中需要观察的属性加上@Trace标签，可以使用makeObserved使得当前对象可以- 被观察。
- 当前类的成员属性不能被修改：因为@Trace观察类属性会动态修改类的属性，这个行为在@Sendable装饰的class中是不被允许- 的，此时可以使用makeObserved。
- interface或者JSON.parse返回的匿名对象：这类场景往往没有明确的class声明，开发者无法使用@Trace标记当前属性可以被观察，此时可以使用makeObserved。

- makeObserved仅支持非空的对象类型传参。
- makeObserved不支持传入被@ObservedV2、@Observed装饰的类的实例和被makeObserved封装过的代理数据。为了防止数据被双重代理，makeObserved发现入参为上述情况时则直接返回，不做处理。
- makeObserved可以用在@Component装饰的自定义组件中，但不能和状态管理V1的状态变量装饰器配合使用，如果一起使用，则会抛出运行时异常。

```ts
import { UIUtils } from '@kit.ArkUI';
class Info {
  public id: number = 0;
  constructor(id: number) {
    this.id = id;
  }
}
@Entry
@ComponentV2
struct Page2 {
  @Local message: Info = UIUtils.makeObserved(new Info(20));
  build() {
    Column() {
      Button(`change id`).onClick(() => {
        this.message.id++;
      })
      Button(`change Info ${this.message.id}`).onClick(() => {
        this.message = new Info(30);
      })
      Button(`change Info1 ${this.message.id}`).onClick(() => {
        this.message = UIUtils.makeObserved(new Info(30));
      })
    }
  }
}
```


## addMonitor/clearMonitor接口

装饰器@Monitor如果声明在@ObservedV2和@ComponentV2中，会使得开发者构造出的所有的@ObservedV2和@ComponentV2的实例，都默认有同样的@Monitor的监听回调，且无法取消或删除对应的监听回调。

如果开发者希望动态给@ObservedV2和@ComponentV2实例添加或者删除监听函数，则可以使用addMonitor和clearMonitor接口。

```ts
import { UIUtils } from '@kit.ArkUI';

@ObservedV2
class User {
  @Trace age: number = 0;
  @Trace name: string = 'Jack';

  onChange1(mon: IMonitor) {
    mon.dirty.forEach((path: string) => {
      console.info(`onChange1: User property ${path} change from ${mon.value(path)?.before} to ${mon.value(path)?.now}`);
    });
  }

  constructor() {
    UIUtils.addMonitor(this, ['age', 'name'], this.onChange1);
  }
}

@Entry
@ComponentV2
struct Page {
  user: User = new User();

  build() {
    Column() {
      Text(`User name ${this.user.name}`)
        .fontSize(20)
        .onClick(() => {
          // 改变name，回调onChange1监听函数
          this.user.name += '!';
        })
      Text(`User age ${this.user.age}`)
        .fontSize(20)
        .onClick(() => {
          // age自增，回调onChange1监听函数
          this.user.age++;
        })
      Button('clear name and age monitor fun')
        .onClick(() => {
          // 删除age和name的onChange1监听函数
          // 再次点击Text组件改变name和age，无监听函数回调
          UIUtils.clearMonitor(this.user, ['age', 'name'], this.user.onChange1);
        })
    }
  }
}
```

- addMonitor/clearMonitor仅支持对@ComponentV2和@ObservedV2装饰（至少有一个@Trace装饰的变量）的实例添加/取消回调
- addMonitor/clearMonitor观察路径必须为string或者为数组
- addMonitor的回调函数必须存在，类型必须为方法类型，且不能为匿名函数


## applySync/flushUpdates/flushUIUpdates

为了实现状态管理V2与animateTo等动效的同步刷新，开发者可以使用applySync、flushUpdates或flushUIUpdates接口。

与状态管理V1不同的是，状态管理V2修改完状态变量后不会立即标脏，而是抛出一个Promise微任务（优先级低于宏任务），该微任务在当前宏任务执行完成后才会处理自定义组件标脏。而animateTo动效会立刻刷新已标脏节点来决定动效首帧。如果动效中使用了V2状态变量，并且在动效前修改了该状态变量，由于调用animateTo时状态变量的变化尚未标脏，这会导致animateTo的动效首帧不符合预期。为此，引入applySync、flushUpdates和flushUIUpdates接口，实现状态管理V2的同步标脏，确保动效达到预期效果。

applySync接口用于同步刷新指定的状态变量，该接口接收一个闭包函数，仅刷新闭包函数内的修改，包括更新@Computed计算、@Monitor回调以及重新渲染UI节点。

```ts
import { UIUtils } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {
  @Local w: number = 50; // 宽度
  @Local h: number = 50; // 高度
  @Local message: string = 'Hello';

  @Monitor('message')
  onMessageChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      console.info(`${path} change from ${monitor.value(path)?.before} to ${monitor.value(path)?.now}`);
    });
  }

  build() {
    Column() {
      Button('change size')
        .margin(20)
        .onClick(() => {
          // 在执行动画前，存在额外的修改
          UIUtils.applySync(() => {
            this.w = 100;
            this.h = 100;
            this.message = 'Hello World';
          });

          this.getUIContext().animateTo({
            duration: 1000
          }, () => {
            this.w = 200;
            this.h = 200;
            this.message = 'Hello ArkUI';
          });
        })
        // ...
      Column() {
        Text(`${this.message}`)
      }
      .backgroundColor('#ff17a98d')
      .width(this.w)
      .height(this.h)
    }
  }
}
```

flushUpdates接口用于同步刷新在调用该函数之前所有的状态变量修改，包括更新@Computed计算、@Monitor回调以及重新渲染UI节点。

```ts
import { UIUtils } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {
  @Local w: number = 50; // 宽度
  @Local h: number = 50; // 高度
  @Local message: string = 'Hello';

  @Monitor('message')
  onMessageChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      console.info(`${path} change from ${monitor.value(path)?.before} to ${monitor.value(path)?.now}`);
    });
  }

  build() {
    Column() {
      Button('change size')
        .margin(20)
        .onClick(() => {
          // 在执行动画前，存在额外的修改
          this.w = 100;
          this.h = 100;
          this.message = 'Hello World';
          UIUtils.flushUpdates();

          this.getUIContext().animateTo({
            duration: 1000
          }, () => {
            this.w = 200;
            this.h = 200;
            this.message = 'Hello ArkUI';
          });
        })
        // ...
      Column() {
        Text(`${this.message}`)
      }
      .backgroundColor('#ff17a98d')
      .width(this.w)
      .height(this.h)
    }
  }
}
```

上述的applySync、flushUpdates接口都会同步执行@Computed计算和@Monitor回调，这会使得在上述示例代码中，一次点击事件里触发了两次@Monitor回调，这可能会与开发者的预期不符，因此引入了flushUIUpdates接口，该接口仅用于同步刷新在调用该函数之前所有的UI节点，不会执行@Computed计算和@Monitor回调。

```ts
import { UIUtils } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {
  @Local message: string = 'Hello';

  @Monitor('message')
  onMessageChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      console.info(`${path} change from ${monitor.value(path)?.before} to ${monitor.value(path)?.now}`);
    });
  }

  build() {
    Column() {
      Text(`message: ${this.message}`)
      Button('change size')
        .margin(20)
        .onClick(() => {
          // test1：调用applySync接口，日志打印两次
          // UIUtils.applySync(() => { this.message = 'Hello World'; });

          // test2：调用flushUpdates接口，日志打印两次
          // this.message = 'Hello World';
          // UIUtils.flushUpdates();

          // test3：调用flushUIUpdates接口，日志打印一次
          this.message = 'Hello World';
          UIUtils.flushUIUpdates();
          this.message = 'Hello ArkUI';
        })
        // ...
    }
  }
}
```

## !!双向绑定语法

!!双向绑定语法，是一个语法糖方便开发者实现数据双向绑定，用于初始化子组件的@Param和@Event。其中@Event方法名需要声明为“$”+ @Param属性名，详见使用场景。

- 如果使用了!!双向绑定语法，表明父组件的变化会同步给子组件，子组件的变化也会同步给父组件。
- 父组件未使用!!时，变化是单向的。


