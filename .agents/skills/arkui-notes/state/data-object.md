

### 细粒度与深度观测 (`@ObservedV2` + `@Trace`)
@ObservedV2装饰器与@Trace装饰器用于装饰类以及类中的属性，使得被装饰的类和属性具有深度观测的能力：

- @ObservedV2装饰器与@Trace装饰器需要配合使用，单独使用@ObservedV2装饰器或@Trace装饰器没有任何作用。
- 被@Trace装饰器装饰的属性property变化时，仅会通知property关联的组件进行刷新。
- 在嵌套类中，嵌套类中的属性property被@Trace装饰且嵌套类被@ObservedV2装饰时，才具有触发UI刷新的能力。
- 在继承类中，父类或子类中的属性property被@Trace装饰且该property所在类被@ObservedV2装饰时，才具有触发UI刷新的能力。
- 未被@Trace装饰的属性用在UI中无法感知到变化，也无法触发UI刷新。
- 使用@ObservedV2与@Trace装饰器的类，需通过new操作符实例化后，才具备被观测变化的能力。


```typescript
@ObservedV2
class UserInfo {
  @Trace name: string = ""; // 追踪 name
  @Trace detail: { age: number } = { age: 0 }; // 追踪 detail 对象本身
}

@ComponentV2
struct Page {
  @Local user: UserInfo = new UserInfo();
  
  build() {
    // 修改 user.name 或 user.detail 都会自动触发 UI 刷新
    Text(this.user.name);
  }
}
```


### 获取新旧值 (`@Monitor`)
@Monitor装饰器用于监听状态变量修改，使得状态变量具有深度监听的能力：

- @Monitor装饰器支持在@ComponentV2装饰的自定义组件中使用，未被状态变量装饰器@Local、@Param、@Provider、@Consumer、@Computed装饰的变量无法被@Monitor监听到变化。
- @Monitor装饰器支持在类中与@ObservedV2、@Trace配合使用，不允许在未被@ObservedV2装饰的类中使用@Monitor装饰器。未被@Trace装饰的属性无法被@Monitor监听到变化。
- 当观测的属性变化时，@Monitor装饰器定义的回调方法将被调用。判断属性是否变化使用的是严格相等（===），当严格相等判断的结果是false（即不相等）的情况下，就会触发@Monitor的回调。当在一次事件中多次改变同一个属性时，将会使用初始值和最终值进行比较以判断是否变化。
- 单个@Monitor装饰器能够同时监听多个属性的变化，当这些属性在一次事件中共同变化时，只会触发一次@Monitor的回调方法。
- @Monitor装饰器具有深度监听的能力，能够监听嵌套类、多维数组、对象数组中指定项的变化。对于嵌套类、对象数组中成员属性变化的监听要求该类被@ObservedV2装饰且该属性被@Trace装饰。
- 当@Monitor监听整个数组时，更改数组的某一项不会被监听到。无法监听内置类型（Array、Map、Date、Set）的API调用引起的变化。
- 在继承类场景中，可以在父子组件中对同一个属性分别定义@Monitor进行监听，当属性变化时，父子组件中定义的@Monitor回调均会被调用。
- 和@Watch装饰器类似，开发者需要自己定义回调函数，区别在于@Watch装饰器将函数名作为参数，而@Monitor直接装饰回调函数。@Monitor与@Watch的对比可以查看@Monitor与@Watch的对比。

```ts
import { hilog } from '@kit.PerformanceAnalysisKit';

class Info {
  public name: string;
  public age: number;

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }
}

@Entry
@ComponentV2
struct Index {
  @Local info: Info = new Info('Tom', 25);

  @Monitor('info')
  infoChange(monitor: IMonitor) {
    hilog.info(0xFF00, 'testTag', '%{public}s', `info change`);
  }

  @Monitor('info.name')
  infoPropertyChange(monitor: IMonitor) {
    hilog.info(0xFF00, 'testTag', '%{public}s', `info name change`);
  }

  build() {
    Column() {
      Text(`name: ${this.info.name}, age: ${this.info.age}`)
      Button('change info')
        .onClick(() => {
          this.info = new Info('Lucy', 18); // 能够监听到
        })
      Button('change info.name')
        .onClick(() => {
          this.info.name = 'Jack'; // 监听不到，name 没有 @Trace
        })
    }
  }
}
```

### 计算属性 (`@Computed`)

当开发者使用相同的计算逻辑重复绑定在UI上时，为了防止重复计算，可以使用@Computed计算属性。计算属性中依赖的状态变量变化时，只会计算一次。这解决了UI多次重用该属性导致的重复计算和性能问题。但需要注意，对于简单计算，不建议使用计算属性，因为计算属性本身也有开销。对于复杂的计算，@Computed能带来性能收益。

```ts
@Computed
get sum() {
  return this.count1 + this.count2 + this.count3;
}
```


