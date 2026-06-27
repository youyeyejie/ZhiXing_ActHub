
## @ComponentV2

和@Component装饰器一样，@ComponentV2装饰器用于装饰自定义组件：

    在@ComponentV2装饰的自定义组件中，开发者仅可以使用全新的状态变量装饰器，包括@Local、@Param、@Once、@Event、@Provider、@Consumer等。

    @ComponentV2装饰的自定义组件暂不支持LocalStorage等现有自定义组件的能力。

    无法同时使用@ComponentV2与@Component装饰同一个struct结构。

    @ComponentV2支持一个可选的ComponentOptions参数，来实现组件冻结功能。

    一个简单的@ComponentV2装饰的自定义组件应具有以下部分：

```ts
@Entry
@ComponentV2 // 装饰器
struct ComponentV2Test { // struct声明的数据结构
  @Local message: string = 'Hello World';
  build() { // build定义的UI
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        // $r('app.float.page_text_font_size')需要替换为开发者所需的资源文件;
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
  }
}
```
除非特别说明，@ComponentV2装饰的自定义组件将与@Component装饰的自定义组件保持相同的行为。

## 状态管理：更纯粹的本地状态 (`@Local`)

@Local表示组件内部的状态，使得自定义组件内部的变量具有观察变化的能力：

- 被@Local装饰的变量无法从外部初始化，因此必须在组件内部进行初始化。
- 当被@Local装饰的变量变化时，会刷新使用该变量的组件。
- @Local支持观测number、boolean、string、Object、class等基本类型以及Array、Set、Map、Date等内置类型。
- @Local的观测能力仅限于被装饰的变量本身。当装饰简单类型时，能够观测到对变量的赋值；当装饰对象类型时，仅能观测到对对象整体的赋值；当装饰数组类型时，能观测到数组整体以及数组元素项的变化；当装饰Array、Set、Map、Date等内置类型时，可以观测到通过API调用带来的变化。详见观察变化。
- @Local支持null、undefined以及联合类型。

状态管理V1使用@State装饰器定义组件中的基础状态变量，该状态变量常用来作为组件内部状态，在组件内使用。但由于@State装饰器又能够从外部初始化，因此无法确保@State装饰变量的初始值一定为组件内部定义的值。

```ts
@Entry
@ComponentV2
struct Index {
  // 点击的次数
  @Local count: number = 0;
  @Local message: string = 'Hello';
  @Local flag: boolean = false;

  build() {
    Column() {
      Text(`${this.count}`)
      Text(`${this.message}`)
      Text(`${this.flag}`)
      Button('change Local')
        .onClick(() => {
          // 当@Local装饰简单类型时，能够观测到对变量的赋值
          this.count++;
          this.message += ' World';
          this.flag = !this.flag;
        })
    }
  }
}
```

### 数据流：单向传递与显式更新 (`@Param` + `@Event`)
@Param表示组件从外部传入的状态，使得父子组件之间的数据能够进行同步：

- @Param装饰的变量支持本地初始化，但不允许在组件内部直接修改。
- 被@Param装饰的变量能够在初始化自定义组件时从外部传入，当数据源也是状态变量时，数据源的修改会同步给@Param。
- @Param可以接受任意类型的数据源，包括普通变量、状态变量、常量、函数返回值等。
- @Param装饰的变量变化时，会刷新该变量关联的组件。
- @Param支持对基本类型（如number、boolean、string、Object、class）、内嵌类型（如Array、Set、Map、Date）- 及null、undefined和联合类型进行观测。
- 对于复杂类型如类对象，@Param会接受数据源的引用。在组件内可以修改类对象中的属性，该修改会同步到数据源。
- @Param的观测能力仅限于被装饰的变量本身。详见观察变化。

```ts
@Entry
@ComponentV2
struct Index {
  // 点击的次数
  @Local count: number = 0;
  @Local message: string = 'Hello';
  @Local flag: boolean = false;

  build() {
    Column() {
      Text(`Local ${this.count}`)
      Text(`Local ${this.message}`)
      Text(`Local ${this.flag}`)
      Button('change Local')
        .onClick(() => {
          // 对数据源的更改会同步给子组件
          this.count++;
          this.message += ' World';
          this.flag = !this.flag;
        })
      Child({
        count: this.count,
        message: this.message,
        flag: this.flag
      })
    }
  }
}

@ComponentV2
struct Child {
  @Require @Param count: number;
  @Require @Param message: string;
  @Require @Param flag: boolean;

  build() {
    Column() {
      Text(`Param ${this.count}`)
      Text(`Param ${this.message}`)
      Text(`Param ${this.flag}`)
    }
  }
}
```


由于@Param装饰的变量在本地无法更改，使用@Event装饰器装饰回调方法并调用，可以实现更新数据源的变量，再通过@Local的同步机制，将修改同步回@Param装饰的变量，以此达到主动更新@Param装饰变量的效果。

@Event用于装饰组件对外输出的方法：

- @Event装饰的回调方法中参数以及返回值由开发者决定。
- @Event装饰非回调类型的变量不会生效。当@Event没有初始化时，会自动生成一个空的函数作为默认回调。
- 当@Event未被外部初始化，但本地有默认值时，会使用本地默认的函数进行处理。

@Param标志着组件的输入，表明该变量受父组件影响，而@Event标志着组件的输出，可以通过该方法影响父组件。使用@Event装饰回调方法是一种规范，表明该回调作为自定义组件的输出。父组件需要判断是否提供对应方法用于子组件更改@Param变量的数据源。

```ts
@Entry
@ComponentV2
struct Index {
  @Local title: string = 'Title One';
  @Local fontColor: Color = Color.Red;

  build() {
    Column() {
      Child({
        title: this.title,
        fontColor: this.fontColor,
        changeFactory: (type: number) => {
          if (type == 1) {
            this.title = 'Title One';
            this.fontColor = Color.Red;
          } else if (type == 2) {
            this.title = 'Title Two';
            this.fontColor = Color.Green;
          }
        }
      })
    }
  }
}

@ComponentV2
struct Child {
  @Param title: string = '';
  @Param fontColor: Color = Color.Black;
  @Event changeFactory: (x: number) => void = (x: number) => {};

  build() {
    Column() {
      Text(`${this.title}`)
        .fontColor(this.fontColor)
      Button('change to Title Two')
        .onClick(() => {
          this.changeFactory(2);
        })
      Button('change to Title One')
        .onClick(() => {
          this.changeFactory(1);
        })
    }
  }
}
```


### 初始化策略：一次性同步 (`@Once`)
想要实现仅从外部初始化一次且不接受后续同步变化的能力，可以使用@Once装饰器搭配@Param装饰器。

@Once装饰器在变量初始化时接受外部传入值进行初始化，后续数据源更改不会同步给子组件：

- @Once必须搭配@Param使用，单独使用或搭配其他装饰器使用都是不允许的。
- @Once不影响@Param的观测能力，仅针对数据源的变化做拦截。
- @Once与@Param装饰变量的先后顺序不影响使用功能。
- @Once与@Param搭配使用时，可以在本地修改@Param变量的值。

```ts
@ComponentV2
struct MyComponent {
  @Param @Once onceParam: string = 'onceParam'; // 正确用法
  @Once onceStr: string = 'Once'; // 错误用法，@Once无法单独使用
  @Local @Once onceLocal: string = 'onceLocal'; // 错误用法，@Once不能与@Local一起使用
// ···
}
```



###  `@Provider` 和 `@Consumer` 装饰器

@Provider和@Consumer用于跨组件层级数据双向同步，可以使得开发者不用拘泥于组件层级。

@Provider，即数据提供方，其所有的子组件都可以通过@Consumer绑定相同的key来获取@Provider提供的数据。@Consumer，即数据消费方，可以通过绑定同样的key获取其最近父节点的@Provider的数据，当查找不到@Provider的数据时，使用本地默认值。

@Provider和@Consumer装饰的数据类型需要一致。@Provider和@Consumer接受可选参数aliasName，没有配置参数时，使用属性名作为默认的aliasName。

开发者在使用@Provider和@Consumer时要注意：

- @Provider和@Consumer强依赖自定义组件层级，@Consumer会因为所在组件的父组件不同，而被初始化为不同的值。
- @Provider和@Consumer相当于把组件粘合在一起了，从组件独立角度考虑，应减少使用@Provider和@Consumer。


```ts
@Entry
@ComponentV2
struct Parent {
  @Provider() str: string = 'hello';

  build() {
    Column() {
      Button(this.str)
        .onClick(() => {
          this.str += '0';
        })
      Child()
    }
  }
}

@ComponentV2
struct Child {
  // @Consumer装饰的属性str和Parent组件中@Provider装饰的属性str名称相同，因此建立了双向绑定关系
  @Consumer() str: string = 'world';

  build() {
    Column() {
      Button(this.str)
        .onClick(() => {
          this.str += '0';
        })
    }
  }
}
```

以下三个例子可清楚介绍@Provider和@Consumer如何使用aliasName进行查找匹配。
```ts
@ComponentV2
struct Parent {
  // 未定义aliasName, 使用属性名'str'作为aliasName
  @Provider() str: string = 'hello';
}

@ComponentV2
struct Child {
  // 定义aliasName为'str'，使用aliasName去寻找
  // 能够在Parent组件上找到, 使用@Provider的值'hello'
  @Consumer('str') str: string = 'world';
}
```
```ts
@ComponentV2
struct Parent {
  // 定义aliasName为'alias'
  @Provider('alias') str: string = 'hello';
}

@ComponentV2
struct Child {
  // 定义aliasName为 'alias'，找到@Provider并获得值'hello'
  @Consumer('alias') str: string = 'world';
}
```
```ts
@ComponentV2
struct Parent {
  // 定义aliasName为'alias'
  @Provider('alias') str: string = 'hello';
}

@ComponentV2
struct Child {
  // 未定义aliasName，使用属性名'str'作为aliasName
  // 没有找到对应的@Provider，使用本地值'world'
  @Consumer() str: string = 'world';
}
```

代码示例

```typescript
@Entry
@ComponentV2
struct Parent {
  // 1. 提供方：本地初始化，指定 alias 为 "userInfo"
  @Provider("userInfo") user: string = "Alice";
  
  // 也可以提供函数
  @Provider("onUpdate") updateFunc: (msg: string) => void = (msg) => { console.log(msg); }

  build() {
    Column() {
      Child() // 中间组件无需感知
    }
  }
}

@ComponentV2
struct Child {
  // 2. 消费方：通过 alias "userInfo" 匹配，变量名可以是 userName
  // 设置默认值 "Guest"，如果找不到 Provider 则显示 Guest
  @Consumer("userInfo") userName: string = "Guest";
  
  @Consumer("onUpdate") onMessage: (msg: string) => void = () => {};

  build() {
    Text(this.userName) // 显示 "Alice"
      .onClick(() => {
        this.onMessage("Hello from Child"); // 调用父组件函数
      })
  }
}
```
