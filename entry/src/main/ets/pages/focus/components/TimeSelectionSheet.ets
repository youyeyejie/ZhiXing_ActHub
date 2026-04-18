import { AppState, useAppState } from '../../../app/AppStates';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit'; 
import { PlayerState } from '../../../core/services/WhiteNoisePlayer'; 
import { FormTypography } from '../../../core/theme/FormTypography';

/**
 * 组件功能简介：
 * - 专注时间选择输入设置组件，提供常用时间预设、自定义时长输入以及白噪音选择。
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
  @Local private restMin: string = '5'; 

  aboutToAppear() {
    this.workMin = Math.floor(this.initialWorkDuration / 60).toString();
    
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
    let totalWork = wMin * 60;

    if (totalWork <= 0) {
      this.safeToast("专注时间不能为0");
      return; 
    }

    let rMin = this.safeParseInt(this.restMin);
    let totalRest = rMin * 60;
    if (totalRest <= 0) totalRest = 5 * 60; 

    this.app.focusEngine.DefaultRestDuration = totalRest;
    
    this.onSave(totalWork, totalRest);
    this.app.nav.back(false);
  }

  @Builder
  private buildPresetItem(icon: Resource, title: string, workMin: number, restMin: number) {
    Row({ space: 6 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.app.theme.palette.primary])

      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
        Text(`${workMin} + ${restMin}`)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textSecondary)
      }
    }
    .layoutWeight(1)
    .height(56) 
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.app.theme.palette.surfaceSecondary)
    .borderRadius(12)
    .onClick(() => {
      this.workMin = `${workMin}`;
      this.restMin = `${restMin}`;
      this.onSave(workMin * 60, restMin * 60);
      this.app.focusEngine.DefaultRestDuration = restMin * 60;
    })
  }

  private isNoiseSelected(file: string): boolean {
    return this.app.whiteNoisePlayer.selectedTrack === file;
  }

  @Builder
  private buildNoiseItem(name: string, file: string, icon: Resource) {
    Row({ space: 6 }) {
      SymbolGlyph(icon)
        .fontSize(16)
        .fontColor([this.isNoiseSelected(file) ? this.app.theme.palette.surface : this.app.theme.palette.textPrimary])
        
      Text(name)
        .fontSize(14)
        .fontWeight(this.isNoiseSelected(file) ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.isNoiseSelected(file) ? this.app.theme.palette.surface : this.app.theme.palette.textPrimary)
    }
    .layoutWeight(1)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isNoiseSelected(file) ? this.app.theme.palette.primary : this.app.theme.palette.surfaceSecondary)
    .borderRadius(12)
    .onClick(() => {
      // 🌟 修改点 1：如果点击的已经是当前选中的白噪音，直接返回，不再允许取消选中
      if (this.isNoiseSelected(file)) {
        return;
      }

      // 🌟 修改点 2：确定是选择了新的白噪音后，直接赋新值给全局状态
      this.app.whiteNoisePlayer.selectedTrack = file;

      // 🌟 修改点 3：如果当前白噪音正在播放，直接无缝切歌
      if (this.app.whiteNoisePlayer.state === PlayerState.PLAYING) {
        const context = getContext(this) as common.UIAbilityContext;
        this.app.whiteNoisePlayer.playWhiteNoise(context, file);
      }
    })
  }

  @Builder
  private buildSaveButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.save'))
        .fontSize(18)
        .fontColor([this.app.theme.palette.surface]);
    }
      .width(34)
      .height(34)
      .backgroundColor(this.app.theme.palette.primary)
      .fontColor(this.app.theme.palette.surface)
      .onClick(() => {
        this.submit();
      })
  }

  @Builder
  private buildContent() {
    Column({ space: 14 }) { 
      Row({ space: 10 }) {
        Text("专注设置")
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1);
        
        this.buildSaveButton();
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      Text("自定义时长")
        .fontSize(FormTypography.LABEL_SIZE)
        .fontColor(this.app.theme.palette.textSecondary)
        .padding({ left: 8, right: 8 });

      Row() {
        Row() {
          Text("专注")
            .fontSize(FormTypography.LABEL_SIZE)
            .fontColor(this.app.theme.palette.textSecondary)
          TextInput({ text: this.workMin })
            .type(InputType.Number)
            .fontSize(FormTypography.INPUT_CONTENT_SIZE)
            .fontColor(this.app.theme.palette.textPrimary)
            .width(50)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.app.theme.palette.transparent)
            .onChange((value: string) => { this.workMin = value; })
            Text("分钟")
            .fontSize(FormTypography.LABEL_SIZE)
            .fontColor(this.app.theme.palette.textSecondary)
        }

        Divider()
          .vertical(true)
          .height(16)
          .color(this.app.theme.palette.textTertiary)
          .opacity(0.3)

        Row() {
          Text("休息")
            .fontSize(FormTypography.LABEL_SIZE)
            .fontColor(this.app.theme.palette.textSecondary)
          TextInput({ text: this.restMin })
            .type(InputType.Number)
            .fontSize(FormTypography.INPUT_CONTENT_SIZE)
            .fontColor(this.app.theme.palette.textPrimary)
            .width(50)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.app.theme.palette.transparent)
            .onChange((value: string) => { this.restMin = value; })
          Text("分钟")
            .fontSize(FormTypography.LABEL_SIZE)
            .fontColor(this.app.theme.palette.textSecondary)
          }
        }
        .width("100%")
        .height(56)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(12)
        .justifyContent(FlexAlign.SpaceEvenly) 

      Row({ space: 12 }) {
        this.buildPresetItem($r('sys.symbol.timer_circle_fill'), "标准", 25, 5)
        this.buildPresetItem($r('sys.symbol.book_open_fill'), "课堂", 45, 10)
        this.buildPresetItem($r('sys.symbol.clock_fill'), "小时", 60, 10)
      }
      .width("100%")

      Text("白噪音")
        .fontSize(FormTypography.LABEL_SIZE)
        .fontColor(this.app.theme.palette.textSecondary)
        .padding({ left: 8, right: 8 });

      Row({ space: 12 }) {
        this.buildNoiseItem('雨声', 'rain.mp3', $r('sys.symbol.icloud'))
        this.buildNoiseItem('流水', 'water.mp3', $r('sys.symbol.drop'))
        this.buildNoiseItem('海浪', 'sea.mp3', $r('sys.symbol.music'))
      }
      .width("100%")

      Row({ space: 4 }) {
        SymbolGlyph($r('sys.symbol.lightbulb'))
          .fontSize(14)
          .fontColor([this.app.theme.palette.textTertiary])
        
        Text("专注时，长按音乐按钮，可修改播放的白噪音")
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
    }
    .width("100%")
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      this.buildContent()
    }
    .width("100%")
    .justifyContent(FlexAlign.Start)
  }
}