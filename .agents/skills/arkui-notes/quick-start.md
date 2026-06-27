
## 基本语法概述

如下图所示，点击“按钮”时，文本内容从“Hello World”变为“Hello ArkUI”。
```ts
// Entry：应用入口
// @Component：装饰器，用于定义自定义组件
@Component
struct Hello {
  // @State：状态装饰器，用于管理组件内部的状态变量
  @State myText: string = 'World';

  // build：构建 UI 描述
  build() {
    // Column：系统组件，用于垂直布局
    Column() {
      // Text：系统组件，用于显示文本
      // `${this.myText}`：数据绑定，将状态变量插入文本
      Text(`Hello ${this.myText}`)
        .fontSize(50) // 属性方法：设置字体大小

      // Divider：系统组件，用于显示分隔线
      Divider()

      // Button：系统组件，用于触发点击事件
      Button('Click me')
        .onClick(() => { // 事件方法：处理点击事件
          this.myText = 'ArkUI'; // 更新状态变量
        })
        .height(50) // 属性方法：设置高度
        .width(100) // 属性方法：设置宽度
        .margin({ top: 20 }) // 属性方法：设置外边距
    }
  }
}
```

- UI装饰器： 用于装饰类、结构、方法以及变量，并赋予其特殊的含义。如上述示例中@Entry、@Component和@State都是装饰器，@Component表示自定义组件，@Entry表示该自定义组件为入口组件，@State表示组件中的状态变量，状态变量变化会触发UI刷新。
- UI描述：以声明式的方式来描述UI的结构，例如build()方法中的代码块。
- 自定义组件：可复用的UI单元，可组合其他组件，如上述被@Component装饰的struct Hello。
- 系统组件：ArkUI框架中默认内置的基础和容器组件，可以直接调用，例如示例中的Column、Text、Divider、Button。
- 属性方法：组件可以通过链式调用配置多项属性，如fontSize()、width()、height()、backgroundColor()等。
- 事件方法：组件可以通过链式调用设置多个事件的响应逻辑，如跟随在Button后面的onClick()。

除此之外，ArkTS扩展了多种语法范式来使开发更加便捷：

- @Builder/@BuilderParam：特殊的封装UI描述的方法，细粒度的封装和复用UI描述。
- @Extend/@Styles：扩展系统组件和封装属性样式，更灵活地组合系统组件。
- stateStyles：多态样式，可以依据组件的内部状态的不同，设置不同样式。

注：箭头函数内部的this是词法作用域，由上下文确定。匿名函数可能会出现this指向不明确的问题，因此在ArkTS中不允许使用。

## 声明式UI

ArkTS以声明方式组合和扩展组件来描述应用程序的UI，同时还提供了基本的属性、事件和子组件配置方法，帮助开发者实现应用交互逻辑。

创建组件不需要使用new关键字。

### 配置属性

属性方法以“.”链式调用配置组件样式和其他属性，建议每个属性方法单独一行。

```ts
// 配置Text组件的字体大小。
Text('test')
  .fontSize(12)
// 配置组件的多个属性。
Image('test.jpg')
  .alt('error.jpg')
  .width(100)
  .height(100)
// 对于系统组件，ArkUI还为其属性预定义了一些枚举类型供开发者调用，枚举类型可以作为参数传递，但必须满足参数类型要求。
Text('hello')
  .fontSize(20)
  .fontColor(Color.Red)
  .fontWeight(FontWeight.Bold)
// 使用箭头函数配置组件的事件方法。
Button('Click me')
  .onClick(() => {
    this.myText = 'ArkUI';
  })
// 使用组件的成员函数配置组件的事件方法，需要bind this。ArkTS语法不建议使用成员函数配合bind this来配置组件的事件方法。
  myClickHandler(): void {
    this.counter += 2;
  }
   Button('add counter')
     .onClick(this.myClickHandler.bind(this))
// 
```

### 配置子组件

如果组件支持子组件配置，则需在尾随闭包"{...}"中为组件添加子组件的UI描述。Column、Row、Stack、Grid、List等组件都是容器组件。

```ts
// 以下是简单的Column组件配置子组件的示例。
Column() {
  Text('Hello')
    .fontSize(100)
  Divider()
  Text(this.myText)
    .fontSize(100)
    .fontColor(Color.Red)
}
```

## 定义子组件

自定义组件基于struct实现，struct + 自定义组件名 + {...}的组合构成自定义组件，不能有继承关系。对于struct的实例化，可以省略new。

@Entry装饰的自定义组件将作为UI页面的入口。在单个UI页面中，仅允许存在一个由@Entry装饰的自定义组件作为页面的入口。

@ComponentV2装饰的struct为V2自定义组件，可以使用状态管理V2版本装饰器的能力。详见 [管理组件拥有的状态](./state/component.md)

build()函数用于定义自定义组件的声明式UI描述，自定义组件必须定义build()函数。

@ReusableV2装饰V2自定义组件，使得该自定义组件具有被复用的能力。详细请参考：@ReusableV2装饰器：V2组件复用。

自定义组件除了必须要实现build()函数外，还可以实现其他成员函数，成员函数具有以下约束：
- 自定义组件的成员函数仅能从组件内部访问，且不建议声明为静态函数。
自定义组件可以包含成员变量，成员变量具有以下约束：
- 自定义组件的成员变量仅能从组件内部访问，且不建议声明为静态变量。
- 自定义组件的成员变量本地初始化有些是可选的，有些是必选的。具体是否需要本地初始化，是否需要从父组件通过参数传递初始化子组件的成员变量，请参考状态管理。
