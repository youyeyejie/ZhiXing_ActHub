# MVVM模式（V2）

在应用开发中，UI的更新需要随着数据状态的变化进行实时同步，而这种同步往往决定了应用程序的性能和用户体验。为了解决数据与UI同步的复杂性，ArkUI采用了Model-View-ViewModel（MVVM）架构模式。MVVM将应用分为Model、View和ViewModel三个核心部分，实现数据、视图与逻辑的分离。通过这种模式，UI可以随着状态的变化自动更新，无需手动处理，从而高效管理数据和视图的绑定与更新。

- Model：存储和管理应用数据及业务逻辑，不直接与用户界面交互。通常从后端接口获取数据，是应用程序的数据基础，确- 数据的一致性和完整性。
- View：负责用户界面展示数据并与用户交互，不包含任何业务逻辑。它通过绑定ViewModel层提供的数据来动态更新UI。
- ViewModel：负责管理UI状态和交互逻辑。作为连接Model和View的桥梁，ViewModel监控Model数据的变化，通知View更新UI，同时处理用户交互事件并转换为数据操作。

本节将通过一个简单的todolist示例，逐步引入和使用状态管理V2的装饰器及工具，从基础的静态任务列表开始，逐步扩展功能。每个步骤都基于上一步扩展，帮助开发者循序渐进地理解并掌握各个装饰器的使用方法。

## 实例

### 基础示例

首先，从静态待办事项列表开始。在示例1中，任务是静态的，没有状态变化和动态交互。

```ts
// src/main/ets/pages/BasicPage.ets
@Entry
@ComponentV2
struct TodoList {
  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      Text('task1')
      Text('task2')
      Text('task3')
    }
  }
}
```

### 添加@Local，实现对组件内部状态观测

完成静态待办列表展示后，为了让用户能够更改任务的完成状态，需要使待办事项能够响应交互并动态更新显示。为此，引入@Local装饰器管理组件内部的状态。被@Local装饰的变量发生变化时，触发绑定的UI组件刷新。

在示例2中，新增@Local装饰的isFinish属性代表任务是否完成。两个图标finished.png和unfinished.png用于展示任务完成或未完成的状态。点击待办事项时，isFinish状态切换，更新图标和文本删除线的效果。

```ts
// src/main/ets/pages/LocalPage.ets
@Entry
@ComponentV2
struct TodoList {
  @Local isFinish: boolean = false;

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      Row() {
        // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
        Image(this.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
          .width(28)
          .height(28)
        Text('task1')
          .decoration({ type: this.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
      }
      .onClick(() => this.isFinish = !this.isFinish)
    }
  }
}
```

### 添加@Param，实现组件接收外部输入

实现任务本地状态切换后，为增强待办事项列表的灵活性，需要能够动态设置每个任务的名称，而不是固定在代码中。引入@Param装饰器后，子组件被装饰的变量可以接收父组件传入的值，实现单向数据同步。@Param默认只读，使用@Param @Once可在子组件中对传入的值进行本地更新。

在示例3中，每个待办事项抽象为TaskItem组件。@Param修饰的taskName属性从父组件TodoList传入任务名称，使TaskItem组件灵活且可复用，能够接收并渲染不同的任务名称。@Param @Once装饰的isFinish属性接收初始值后，可在子组件内更新。

```ts
// src/main/ets/pages/ParamPage.ets
@ComponentV2
struct TaskItem {
  @Param taskName: string = '';
  @Param @Once isFinish: boolean = false;

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
      Text(this.taskName)
        .decoration({ type: this.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
    }
    .onClick(() => this.isFinish = !this.isFinish)
  }
}

@Entry
@ComponentV2
struct TodoList {
  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      TaskItem({ taskName: 'Task 1', isFinish: false })
      TaskItem({ taskName: 'Task 2', isFinish: false })
      TaskItem({ taskName: 'Task 3', isFinish: false })
    }
  }
}
```

### 添加@Event，实现组件对外输出

实现任务名称动态设置后，任务列表内容固定。为了实现任务列表的动态扩展，需要增加任务项的添加和删除功能。为此，引入@Event装饰器，用于子组件向父组件输出数据。

在示例4中，每个TaskItem增加了删除按钮，同时任务列表底部增加了添加新任务的功能。点击子组件TaskItem的“删除”按钮时，deleteTask事件会被触发并传递给父组件TodoList，父组件响应并移除任务。通过使用@Param和@Event，子组件不仅能接收父组件的数据，还能将事件传递回父组件，实现数据双向同步。

```ts
// src/main/ets/pages/EventPage.ets
@ComponentV2
struct TaskItem {
  @Param taskName: string = '';
  @Param @Once isFinish: boolean = false;
  @Event deleteTask: () => void = () => {};

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
      Text(this.taskName)
        .decoration({ type: this.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
      Button('Delete')
        .onClick(() => {
          this.deleteTask();
        })
    }
    .onClick(() => {
      this.isFinish = !this.isFinish;
    })
  }
}

@Entry
@ComponentV2
struct TodoList {
  @Local tasks: string[] = ['task1', 'task2', 'task3'];
  @Local newTaskName: string = '';

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      ForEach(this.tasks, (task: string) => {
        TaskItem({
          taskName: task,
          isFinish: false,
          deleteTask: () => {
            this.tasks.splice(this.tasks.indexOf(task), 1);
          }
        })
      })
      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => {
            this.newTaskName = value;
          })
          .width('70%')
        Button('+')
          .onClick(() => {
            this.tasks.push(this.newTaskName);
            this.newTaskName = '';
          })
      }
    }
  }
}
```

### 添加Repeat，实现子组件复用

添加任务增删功能后，任务列表项增加，需要高效渲染多个结构相同的子组件，提高界面性能。引入Repeat组件，优化任务列表渲染。

Repeat支持两种场景：懒加载场景和非懒加载场景。

- 懒加载场景适用于大量数据的场景，在滚动类容器中按需加载组件，极大节省内存和提升渲染效率。
- 非懒加载场景适用于数据量较小的场景，一次性渲染所有组件，并在数据变化时仅更新需要变化的部分，避免整体重新渲染。

在示例5中，由于任务量较少，使用Repeat非懒加载场景。新建任务数组tasks，并使用Repeat方法迭代数组中的每一项，动态生成并复用TaskItem组件。任务增删时，这种方式能高效复用已有组件，避免重复渲染，提高界面响应速度和性能。这种机制有效地提高了代码的复用性和渲染效率。

```ts
// src/main/ets/pages/RepeatPage.ets
@ComponentV2
struct TaskItem {
  @Param taskName: string = '';
  @Param @Once isFinish: boolean = false;
  @Event deleteTask: () => void = () => {};

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
      Text(this.taskName)
        .decoration({ type: this.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
      Button('Delete')
        .onClick(() => {
          this.deleteTask();
        })
    }
    .onClick(() => {
      this.isFinish = !this.isFinish;
    })
  }
}

@Entry
@ComponentV2
struct TodoList {
  @Local tasks: string[] = ['task1', 'task2', 'task3'];
  @Local newTaskName: string = '';

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      Repeat<string>(this.tasks)
        .each((obj: RepeatItem<string>) => {
          TaskItem({
            taskName: obj.item,
            isFinish: false,
            deleteTask: () => {
              this.tasks.splice(this.tasks.indexOf(obj.item), 1);
            }
          })
        })
      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => {
            this.newTaskName = value;
          })
          .width('70%')
        Button('+')
          .onClick(() => {
            this.tasks.push(this.newTaskName);
            this.newTaskName = '';
          })
      }
    }
  }
}
```

### 添加@ObservedV2，@Trace，实现类属性观测变化

实现多个功能后，任务列表管理变得复杂。为了有效处理任务数据的变化，特别是在多层嵌套结构中，需要确保属性变化能够被深度观测并自动更新UI。为此，引入了@ObservedV2和@Trace装饰器。与仅能观测对象及其第一层变化的@Local不同，@ObservedV2和@Trace适用于多层嵌套和继承等复杂场景。在@ObservedV2装饰的类中，@Trace装饰的属性变化时，会触发绑定的UI组件刷新。

在示例6中，任务（Task）被抽象为一个类，并用@ObservedV2标记该类，用@Trace标记isFinish属性。TodoList组件嵌套了TaskItem，TaskItem又嵌套了Task。在最外层的TodoList中，添加了"全部完成"和"全部未完成"的按钮，每次点击这些按钮都会直接更新最内层Task类的isFinish属性。@ObservedV2和@Trace确保可以观察到对应isFinish UI组件的刷新，从而实现了对嵌套类属性的深度观测。

```ts
// src/main/ets/pages/ObservedV2TracePage.ets
@ObservedV2
class Task {
  public taskName: string = '';
  @Trace public isFinish: boolean = false;

  constructor(taskName: string, isFinish: boolean) {
    this.taskName = taskName;
    this.isFinish = isFinish;
  }
}

@ComponentV2
struct TaskItem {
  @Param task: Task = new Task('', false);
  @Event deleteTask: () => void = () => {};

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.task.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
      Text(this.task.taskName)
        .decoration({ type: this.task.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
      Button('Delete')
        .onClick(() => {
          this.deleteTask();
        })
    }
    .onClick(() => {
      this.task.isFinish = !this.task.isFinish;
    })
  }
}

@Entry
@ComponentV2
struct TodoList {
  @Local tasks: Task[] = [
    new Task('task1', false),
    new Task('task2', false),
    new Task('task3', false),
  ];
  @Local newTaskName: string = '';

  finishAll(ifFinish: boolean) {
    for (let task of this.tasks) {
      task.isFinish = ifFinish;
    }
  }

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      Repeat<Task>(this.tasks)
        .each((obj: RepeatItem<Task>) => {
          TaskItem({
            task: obj.item,
            deleteTask: () => {
              this.tasks.splice(this.tasks.indexOf(obj.item), 1);
            }
          })
        })
      Row() {
        Button('All Completed')
          .onClick(() => {
            this.finishAll(true);
          })
        Button('All Not Completed')
          .onClick(() => {
            this.finishAll(false);
          })
      }
      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => {
            this.newTaskName = value;
          })
          .width('70%')
        Button('+')
          .onClick(() => {
            this.tasks.push(new Task(this.newTaskName, false));
            this.newTaskName = '';
          })
      }
    }
  }
}
```

### 添加@Monitor，@Computed，实现监听状态变量和计算属性

在当前任务列表功能基础上，为了提升体验，可以增加一些额外的功能，如任务状态变化的监听和未完成任务数量的动态计算。为此，引入@Monitor和@Computed装饰器。@Monitor用于深度监听状态变量，在属性变化时触发自定义回调方法。@Computed用于装饰getter方法，检测被计算的属性变化。被计算的值变化时，仅计算一次，减少重复计算开销。

在示例7中，使用@Monitor装饰器深度监听TaskItem中task的isFinish属性。当任务完成状态变化时，触发onTaskFinished回调，记录任务完成状态的变化。同时，新增对todolist中未完成任务数量的记录。使用@Computed装饰器定义tasksUnfinished，每当任务状态变化时自动重新计算。通过这两个装饰器，实现了状态变量的深度监听和高效的计算属性。

```ts
// src/main/ets/pages/MonitorComputedPage.ets
import { hilog } from '@kit.PerformanceAnalysisKit';

@ObservedV2
class Task {
  public taskName: string = '';
  @Trace public isFinish: boolean = false;

  constructor(taskName: string, isFinish: boolean) {
    this.taskName = taskName;
    this.isFinish = isFinish;
  }
}

@ComponentV2
struct TaskItem {
  @Param task: Task = new Task('', false);
  @Event deleteTask: () => void = () => {};

  @Monitor('task.isFinish')
  onTaskFinished(mon: IMonitor) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'task' + this.task.taskName + 'The completion status of the' + mon.value()?.before + 'has become' + mon.value()?.now);
  }

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.task.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
      Text(this.task.taskName)
        .decoration({ type: this.task.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
      Button('Delete')
        .onClick(() => {
          this.deleteTask();
        })
    }
    .onClick(() => {
      this.task.isFinish = !this.task.isFinish;
    })
  }
}

@Entry
@ComponentV2
struct TodoList {
  @Local tasks: Task[] = [
    new Task('task1', false),
    new Task('task2', false),
    new Task('task3', false),
  ];
  @Local newTaskName: string = '';

  finishAll(ifFinish: boolean) {
    for (let task of this.tasks) {
      task.isFinish = ifFinish;
    }
  }

  @Computed
  get tasksUnfinished(): number {
    return this.tasks.filter(task => !task.isFinish).length;
  }

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin({ bottom: 10 })
      Text('Unfinished task' + `：${this.tasksUnfinished}`)
      Repeat<Task>(this.tasks)
        .each((obj: RepeatItem<Task>) => {
          TaskItem({
            task: obj.item,
            deleteTask: () => {
              this.tasks.splice(this.tasks.indexOf(obj.item), 1);
            }
          })
        })
      Row() {
        Button('All Completed')
          .onClick(() => {
            this.finishAll(true);
          })
        Button('All Not Completed')
          .onClick(() => {
            this.finishAll(false);
          })
      }
      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => {
            this.newTaskName = value;
          })
          .width('70%')
        Button('+')
          .onClick(() => {
            this.tasks.push(new Task(this.newTaskName, false));
            this.newTaskName = '';
          })
      }
    }
  }
}
```

### 添加@Builder，实现自定义构建函数

随着应用功能逐步扩展，代码中的某些UI元素开始重复，不仅增加了代码量，也让维护变得复杂。为解决此问题，建议使用@Builder装饰器，将重复的UI组件抽象为独立的构建方法，便于复用和代码模块化。

```ts
// src/main/ets/pages/BuilderPage.ets
import { AppStorageV2, PersistenceV2, Type } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { Setting } from './SettingPage';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ObservedV2
class Task {
  // 未实现构造函数，因为@Type当前不支持带参数的构造函数。
  @Trace public taskName: string = 'Todo';
  @Trace public isFinish: boolean = false;
}

@Builder
function actionButton(text: string | Resource, onClick: () => void) {
  Button(text, { buttonStyle: ButtonStyleMode.NORMAL })
    .onClick(onClick)
    .margin({
      left: 10,
      right: 10,
      top: 5,
      bottom: 5
    })
}

@ObservedV2
class TaskList {
  // 对于复杂对象需要@Type修饰，确保序列化成功。
  @Type(Task)
  @Trace public tasks: Task[] = [];

  constructor(tasks: Task[]) {
    this.tasks = tasks;
  }

  async loadTasks(context: common.UIAbilityContext) {
    let getJson = await context.resourceManager.getRawFileContent('defaultTasks.json');
    let textDecoderOptions: util.TextDecoderOptions = { ignoreBOM: true };
    let textDecoder = util.TextDecoder.create('utf-8', textDecoderOptions);
    let result = textDecoder.decodeToString(getJson);
    this.tasks = JSON.parse(result).map((task: Task) => {
      let newTask = new Task();
      newTask.taskName = task.taskName;
      newTask.isFinish = task.isFinish;
      return newTask;
    });
  }
}

@ComponentV2
struct TaskItem {
  @Param task: Task = new Task();
  @Event deleteTask: () => void = () => {};

  @Monitor('task.isFinish')
  onTaskFinished(mon: IMonitor) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'task' + this.task.taskName + 'The completion status of the' + mon.value()?.before + 'has become' + mon.value()?.now);
  }

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.task.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
        .margin({ left: 15, right: 10 })
      Text(this.task.taskName)
        .decoration({ type: this.task.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
        .fontSize(18)
      actionButton('Delete', () => {
        this.deleteTask();
      })
    }
    .height('7%')
    .width('90%')
    .backgroundColor('#90f1f3f5')
    .borderRadius(25)
    .onClick(() => {
      this.task.isFinish = !this.task.isFinish;
    })
  }
}

@Entry
@ComponentV2
struct TodoList {
  @Local taskList: TaskList = PersistenceV2.connect(TaskList, 'TaskList', () => new TaskList([]))!;
  @Local newTaskName: string = '';
  @Local setting: Setting = AppStorageV2.connect(Setting, 'Setting', () => new Setting())!;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear() {
    if (this.taskList.tasks.length === 0) {
      await this.taskList.loadTasks(this.context);
    }
  }

  finishAll(ifFinish: boolean) {
    for (let task of this.taskList.tasks) {
      task.isFinish = ifFinish;
    }
  }

  @Computed
  get tasksUnfinished(): number {
    return this.taskList.tasks.filter(task => !task.isFinish).length;
  }

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin(10)
      Text('Unfinished task' + `：${this.tasksUnfinished}`)
        .margin({ left: 10, bottom: 10 })
      Repeat<Task>(this.taskList.tasks.filter(task => this.setting.showCompletedTask || !task.isFinish))
        .each((obj: RepeatItem<Task>) => {
          TaskItem({
            task: obj.item,
            deleteTask: () => {
              this.taskList.tasks.splice(this.taskList.tasks.indexOf(obj.item), 1);
            }
          })
            .margin(5)
        })
      Row() {
        actionButton('All Completed', (): void => this.finishAll(true))
        actionButton('All Not Completed', (): void => this.finishAll(false))
        actionButton('Setting', (): void => {
          let wantInfo: Want = {
            deviceId: '', // deviceId为空表示本设备。
            bundleName: 'com.samples.statemgmtv2mvvm', // 替换成AppScope/app.json5里的bundleName。
            abilityName: 'SettingAbility',
          };
          this.context.startAbility(wantInfo);
        })
      }
      .margin({ top: 10, bottom: 5 })
      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => {
            this.newTaskName = value;
          })
          .width('70%')
        actionButton('+', (): void => {
          let newTask = new Task();
          newTask.taskName = this.newTaskName;
          this.taskList.tasks.push(newTask);
          this.newTaskName = '';
        })
      }
    }
    .height('100%')
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ left: 15 })
  }
}
```

## 重构代码以符合MVVM架构

前面的例子通过使用一系列的状态管理装饰器，实现了todolist中的数据同步与UI更新。然而，随着应用功能的复杂化，代码的结构变得难以维护，Model、View和ViewModel的职责没有完全分离，存在耦合。为了更好地组织代码和提升可维护性，使用MVVM模式重构代码，进一步将数据层（Model）、逻辑层（ViewModel）和展示层（View）分离。

```ts
export default class TaskModel {
  public taskName: string = 'Todo';
  public isFinish: boolean = false;
}
```
```ts
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import TaskModel from './TaskModel';

export default class TaskListModel {
  public tasks: TaskModel[] = [];

  constructor(tasks: TaskModel[]) {
    this.tasks = tasks;
  }

  async loadTasks(context: common.UIAbilityContext) {
    let getJson = await context.resourceManager.getRawFileContent('defaultTasks.json');
    let textDecoderOptions: util.TextDecoderOptions = { ignoreBOM: true };
    let textDecoder = util.TextDecoder.create('utf-8', textDecoderOptions);
    let result = textDecoder.decodeToString(getJson);
    this.tasks = JSON.parse(result).map((task: TaskModel) => {
      let newTask = new TaskModel();
      newTask.taskName = task.taskName;
      newTask.isFinish = task.isFinish;
      return newTask;
    });
  }
}
```

```ts
// src/main/ets/viewmodel/TaskViewModel.ets
import TaskModel from '../model/TaskModel';

@ObservedV2
export default class TaskViewModel {
  @Trace public taskName: string = 'Todo';
  @Trace public isFinish: boolean = false;

  updateTask(task: TaskModel) {
    this.taskName = task.taskName;
    this.isFinish = task.isFinish;
  }

  updateIsFinish(): void {
    this.isFinish = !this.isFinish;
  }
}
```
```ts
// src/main/ets/viewmodel/TaskListViewModel.ets
import { common } from '@kit.AbilityKit';
import { Type } from '@kit.ArkUI';
import TaskListModel from '../model/TaskListModel';
import TaskViewModel from './TaskViewModel';

@ObservedV2
export default class TaskListViewModel {
  @Type(TaskViewModel)
  @Trace public tasks: TaskViewModel[] = [];

  async loadTasks(context: common.UIAbilityContext) {
    let taskList = new TaskListModel([]);
    await taskList.loadTasks(context);
    for (let task of taskList.tasks) {
      let taskViewModel = new TaskViewModel();
      taskViewModel.updateTask(task);
      this.tasks.push(taskViewModel);
    }
  }

  finishAll(ifFinish: boolean): void {
    for (let task of this.tasks) {
      task.isFinish = ifFinish;
    }
  }

  addTask(newTask: TaskViewModel): void {
    this.tasks.push(newTask);
  }

  removeTask(removedTask: TaskViewModel): void {
    this.tasks.splice(this.tasks.indexOf(removedTask), 1);
  }
}
```

```ts
// src/main/ets/view/TitleView.ets
@ComponentV2
export default struct TitleView {
  @Param tasksUnfinished: number = 0;

  build() {
    Column() {
      Text('To do')
        .fontSize(40)
        .margin(10)
      Text(`All Not Completed：${this.tasksUnfinished}`)
        .margin({ left: 10, bottom: 10 })
    }
  }
}
```
```ts
// src/main/ets/view/ListView.ets
import TaskViewModel from '../viewmodel/TaskViewModel';
import TaskListViewModel from '../viewmodel/TaskListViewModel';
import { Setting } from '../pages/SettingPage';
import { ActionButton } from './BottomView';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
struct TaskItem {
  @Param task: TaskViewModel = new TaskViewModel();
  @Event deleteTask: () => void = () => {};

  @Monitor('task.isFinish')
  onTaskFinished(mon: IMonitor) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'task' + this.task.taskName + 'The completion status of the' + mon.value()?.before + 'has become' + mon.value()?.now);
  }

  build() {
    Row() {
      // 请开发者自行在src/main/resources/base/media路径下添加finished.png和unfinished.png两张图片，否则运行时会因资源缺失而报错。
      Image(this.task.isFinish ? $r('app.media.finished') : $r('app.media.unfinished'))
        .width(28)
        .height(28)
        .margin({ left: 15, right: 10 })
      Text(this.task.taskName)
        .decoration({ type: this.task.isFinish ? TextDecorationType.LineThrough : TextDecorationType.None })
        .fontSize(18)
      ActionButton('Delete', () => this.deleteTask());
    }
    .height('7%')
    .width('90%')
    .backgroundColor('#90f1f3f5')
    .borderRadius(25)
    .onClick(() => this.task.updateIsFinish())
  }
}

@ComponentV2
export default struct ListView {
  @Param taskList: TaskListViewModel = new TaskListViewModel();
  @Param setting: Setting = new Setting();

  build() {
    Repeat<TaskViewModel>(this.taskList.tasks.filter(task => this.setting.showCompletedTask || !task.isFinish))
      .each((obj: RepeatItem<TaskViewModel>) => {
        TaskItem({
          task: obj.item,
          deleteTask: () => this.taskList.removeTask(obj.item)
        }).margin(5)
      })
  }
}
```
```ts
// src/main/ets/view/BottomView.ets
import { common, Want } from '@kit.AbilityKit';
import TaskViewModel from '../viewmodel/TaskViewModel';
import TaskListViewModel from '../viewmodel/TaskListViewModel';

@Builder
export function ActionButton(text: string | Resource, onClick: () => void) {
  Button(text, { buttonStyle: ButtonStyleMode.NORMAL })
    .onClick(onClick)
    .margin({
      left: 10,
      right: 10,
      top: 5,
      bottom: 5
    })
}

@ComponentV2
export default struct BottomView {
  @Param taskList: TaskListViewModel = new TaskListViewModel();
  @Local newTaskName: string = '';
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build() {
    Column() {
      Row() {
        ActionButton('All Completed', (): void => this.taskList.finishAll(true))
        ActionButton('All Not Completed', (): void => this.taskList.finishAll(false))
      }
      .margin({ top: 10 })

      Row() {
        ActionButton('Setting', (): void => {
          let wantInfo: Want = {
            deviceId: '', // deviceId为空表示本设备。
            bundleName: 'com.samples.statemgmtv2mvvm', // 替换成AppScope/app.json5里的bundleName。
            abilityName: 'SettingAbility',
          };
          this.context.startAbility(wantInfo);
        })
      }
      .margin({ bottom: 5 })

      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => this.newTaskName = value)
          .width('70%')
        ActionButton('+', (): void => {
          let newTask = new TaskViewModel();
          newTask.taskName = this.newTaskName;
          this.taskList.addTask(newTask);
          this.newTaskName = '';
        })
      }
    }
  }
}
```
```ts
// src/main/ets/pages/TodoListPage.ets
import TaskListViewModel from '../viewmodel/TaskListViewModel';
import { common } from '@kit.AbilityKit';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { Setting } from '../pages/SettingPage';
import TitleView from '../view/TitleView';
import ListView from '../view/ListView';
import BottomView from '../view/BottomView';

@Entry
@ComponentV2
struct TodoList {
  @Local taskList: TaskListViewModel = PersistenceV2.connect(TaskListViewModel, 'TaskList', () => new TaskListViewModel())!;
  @Local setting: Setting = AppStorageV2.connect(Setting, 'Setting', () => new Setting())!;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear() {
    if (this.taskList.tasks.length === 0) {
      await this.taskList.loadTasks(this.context);
    }
  }

  @Computed
  get tasksUnfinished(): number {
    return this.taskList.tasks.filter(task => !task.isFinish).length;
  }

  build() {
    Column() {
      TitleView({ tasksUnfinished: this.tasksUnfinished })
      ListView({ taskList: this.taskList, setting: this.setting });
      BottomView({ taskList: this.taskList });
    }
    .height('100%')
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ left: 15 })
  }
}
```
```ts
// src/main/ets/pages/SettingPage.ets
import { AppStorageV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@ObservedV2
export class Setting {
  @Trace public showCompletedTask: boolean = true;
}

@Entry
@ComponentV2
struct SettingPage {
  @Local setting: Setting = AppStorageV2.connect(Setting, 'Setting', () => new Setting())!;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build(){
    Column(){
      Text('Setting')
        .fontSize(40)
        .margin({ bottom: 10 })
      Row() {
        Text('Show completed tasks')
        Toggle({ type: ToggleType.Switch, isOn:this.setting.showCompletedTask })
          .onChange((isOn) => {
            this.setting.showCompletedTask = isOn;
          })
      }
      Button('Back to To do')
        .onClick(()=>this.context.terminateSelf())
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
  }
}
```
