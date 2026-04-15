import { AppState, useAppState } from '../../../app/AppStates';
import promptAction from '@ohos.promptAction';

/**
 * 组件功能简介：
 * - 专注时间选择输入设置组件，提供常用时间预设与自定义输入。
 *
 * 可传入项：
 * - @Require @Param initialWorkDuration: number (初始加载的专注时间，单位秒)
 * - @Event onSave: (workDuration: number, restDuration: number) => void (点击保存或预设项时触发，回传设定的工作和休息时间)
 * - @Event onSheetClose: () => void (组件即将销毁时触发的回调，用于通知父组件清理状态)
 *
 * 返回行为：
 * - 渲染包含标题栏、预设快捷选项列表（番茄钟/课堂/一小时）及手动输入框（分/秒）的滚动表单容器。
 *
 * 副作用：
 * - 提交保存时，会直接更新全局引擎 `app.focusEngine.DefaultRestDuration` 的值。
 * - 保存成功或点击预设后，会触发 `promptAction.showToast` 进行系统级弱提示。
 * - 完成操作后调用 `app.nav.back(false)` 触发路由出栈并销毁自身。
 */
@ComponentV2
export struct TimeSelectionSheet {
  @Local private app: AppState = useAppState();

  @Require @Param initialWorkDuration: number;
  @Event onSave: (workDuration: number, restDuration: number) => void = () => {};
  @Event onSheetClose: () => void = () => {};

  @Local private workMin: string = '';
  @Local private workSec: string = '';
  @Local private restMin: string = '5'; 

  aboutToAppear() {
    this.workMin = Math.floor(this.initialWorkDuration / 60).toString();
    this.workSec = (this.initialWorkDuration % 60).toString();
    
    const currentRest = Math.floor(this.app.focusEngine.DefaultRestDuration / 60);
    this.restMin = currentRest > 0 ? currentRest.toString() : '5';
  }

  aboutToDisappear() {
    this.onSheetClose();
  }

  private safeParseInt(val: string, fallback: number = 0): number {
    const parsed = parseInt(val, 10);
    return isNaN(parsed) ? fallback : parsed;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1500 });
    } catch (_error) {}
  }

  private submit(): void {
    let wMin = this.safeParseInt(this.workMin);
    let wSec = this.safeParseInt(this.workSec);
    let totalWork = wMin * 60 + wSec;

    if (totalWork <= 0) {
      this.safeToast("专注时间不能为0");
      return; 
    }

    let rMin = this.safeParseInt(this.restMin);
    let totalRest = rMin * 60;
    if (totalRest <= 0) totalRest = 5 * 60; 

    this.app.focusEngine.DefaultRestDuration = totalRest;
    this.onSave(totalWork, totalRest);
    
    this.safeToast("时间设置已保存");
    this.app.nav.back(false);
  }

  @Builder
  private buildPresetItem(icon: Resource, title: string, workMin: number, restMin: number) {
    Row({ space: 16 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.app.theme.palette.primary])

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.app.theme.palette.textPrimary)
        .layoutWeight(1)
    }
    .width("100%")
    .height(56) // 标准的列表项高度
    .backgroundColor(this.app.theme.palette.surfaceSecondary)
    .borderRadius(12)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.onSave(workMin * 60, restMin * 60);
      this.app.focusEngine.DefaultRestDuration = restMin * 60;
      this.safeToast(`已设置：${title}`);
      this.app.nav.back(false);
    })
  }

  @Builder
  private buildContent() {
    Column({ space: 20 }) { // 稍微加大模块间的间距，让层级更清晰
      Row() {
        Text("时间设置")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        
        Button("保存")
          .type(ButtonType.Capsule)
          .height(40)
          .backgroundColor(this.app.theme.palette.primary)
          .fontColor(this.app.theme.palette.surface)
          .onClick(() => {
            this.submit();
          })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      Column({ space: 10 }) {
        this.buildPresetItem($r('sys.symbol.timer_circle_fill'), "标准番茄钟（25+5）", 25, 5)
        this.buildPresetItem($r('sys.symbol.book_open_fill'), "课堂与课间（45+10）", 45, 10)
        this.buildPresetItem($r('sys.symbol.clock_fill'), "一小时（60+10）", 60, 10)
      }
      .width("100%")

      Column({ space: 10 }) {
        Text("自定义专注时间")
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .width("100%")
          .textAlign(TextAlign.Center) 

        Row({ space: 12 }) {
          TextInput({ text: this.workMin, placeholder: "分" })
            .type(InputType.Number)
            .fontSize(14)
            .layoutWeight(1)
            .textAlign(TextAlign.Center) 
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .borderRadius(12)
            .padding(12)
            .onChange((value: string) => {
              this.workMin = value;
            })
          
          Text("分")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textPrimary)

          TextInput({ text: this.workSec, placeholder: "秒" })
            .type(InputType.Number)
            .fontSize(14)
            .layoutWeight(1)
            .textAlign(TextAlign.Center) 
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .borderRadius(12)
            .padding(12)
            .onChange((value: string) => {
              this.workSec = value;
            })
            
          Text("秒")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textPrimary)
        }
        .width("100%")
        .alignItems(VerticalAlign.Center)
      }
      .width("100%")
      .alignItems(HorizontalAlign.Center) 

      Column({ space: 10 }) {
        Text("自定义休息时间")
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .width("100%")
          .textAlign(TextAlign.Center) 
        
        Row({ space: 12 }) {
          TextInput({ text: this.restMin, placeholder: "分钟数" })
            .type(InputType.Number)
            .fontSize(14)
            .layoutWeight(1)
            .textAlign(TextAlign.Center) 
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
            .borderRadius(12)
            .padding(12)
            .onChange((value: string) => {
              this.restMin = value;
            })
            
          Text("分")
            .fontSize(14)
            .fontColor(this.app.theme.palette.textPrimary)
        }
        .width("50%") 
        .alignItems(VerticalAlign.Center)
      }
      .width("100%")
      .alignItems(HorizontalAlign.Center) 
    }
    .width("100%")
    .alignItems(HorizontalAlign.Center) 
  }

  build() {
    Column() {
      Scroll() {
        this.buildContent()
      }
      .scrollBar(BarState.Off)
      .width("100%")
      .align(Alignment.Top) 
    }
    .width("100%")
    .padding({ bottom: 24 }) 
  }
}