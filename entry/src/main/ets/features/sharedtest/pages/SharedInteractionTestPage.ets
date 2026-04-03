import display from '@ohos.display';
import { CircleButton } from '../../../common/components/buttons/CircleButton';
import { InteractableCard } from '../../../common/components/card/InteractableCard';
import { DetailCard } from '../../../common/components/card/DetailCard';
import { ActionSheet } from '../../../common/components/overlays/ActionSheet';
import { AutoSaveText } from '../../../common/components/form/AutoSaveText';
import { EditableSuite } from '../../../common/components/form/EditableSuite';
import { UndoNotification } from '../../../common/components/feedback/UndoNotification';
import { SearchOverlay } from '../../../common/components/overlays/SearchOverlay';
import { CircularProgress } from '../../../common/components/progress/CircularProgress';

/**
 * 通用交互抽象层测试页。
 * 使用 CustomDialog 打开窗口级浮层，确保可覆盖 TabBar。
 */
@Component
export struct SharedInteractionTestPage {
  @State private keyboardOffset: number = 0;
  @State private undoVisible: boolean = false;
  @State private progress: number = 0.45;
  @State private logs: string[] = [];
  @State private topInset: number = 56;

  private actionSheetDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildActionSheetDialog,
    customStyle: true,
    autoCancel: false,
    alignment: DialogAlignment.Bottom
  });

  private searchDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildSearchDialog,
    customStyle: true,
    autoCancel: false,
    alignment: DialogAlignment.Top
  });

  private detailDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildDetailDialog,
    customStyle: true,
    autoCancel: false,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.applyDeviceTopInset();
  }

  private applyDeviceTopInset(): void {
    try {
      const info = display.getDefaultDisplaySync();
      const longEdge = Math.max(info.width, info.height);
      const shortEdge = Math.max(1, Math.min(info.width, info.height));
      const ratio = longEdge / shortEdge;

      if (ratio >= 2.18) {
        this.topInset = 78;
      } else if (ratio >= 2.0) {
        this.topInset = 66;
      } else {
        this.topInset = 56;
      }
    } catch (_error) {
      this.topInset = 60;
    }
  }

  private pushLog(message: string): void {
    this.logs = [message, ...this.logs].slice(0, 6);
  }

  private cycleProgress(): void {
    const next = this.progress + 0.15;
    this.progress = next > 1 ? 0.1 : next;
  }

  private decreaseProgress(): void {
    const next = this.progress - 0.15;
    this.progress = next < 0 ? 1 : next;
  }

  @Builder
  private buildActionSheetDialog() {
    ActionSheet({
      isVisible: true,
      panelHeight: '70%',
      keyboardOffset: this.keyboardOffset,
      onDismiss: () => {
        this.actionSheetDialogController.close();
      }
    }) {
      Column({ space: 12 }) {
        Text('ActionSheet 内容测试')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);

        EditableSuite({
          title: '动作编辑套件',
          onSaveField: (field: string, value: string) => {
            this.pushLog('EditableSuite 已保存字段: ' + field + ' = ' + value);
          }
        });

        Button('关闭弹层')
          .width('100%')
          .height(42)
          .onClick(() => {
            this.actionSheetDialogController.close();
          });
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%');
    }
  }

  @Builder
  private buildSearchDialog() {
    SearchOverlay({
      isVisible: true,
      placeholder: '输入关键字进行测试',
      topInset: this.topInset,
      onDismiss: () => {
        this.searchDialogController.close();
      },
      onSearch: (keyword: string) => {
        this.pushLog('SearchOverlay 搜索: ' + keyword);
      }
    })
      .width('100%')
      .height('100%');
  }

  @Builder
  private buildDetailDialog() {
    DetailCard({
      isVisible: true,
      onClose: () => {
        this.detailDialogController.close();
      }
    }) {
      Column({ space: 10 }) {
        Text('详情卡片基础组件')
          .fontSize(18)
          .fontWeight(FontWeight.Bold);
        Text('宽度 80%，高度 60%，支持背景遮罩和右上角关闭。')
          .fontSize(13)
          .fontColor('#667085');
        Text('你可以在这里放详情展示、编辑表单或操作按钮。')
          .fontSize(13)
          .fontColor('#667085');
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%');
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: 16 }) {
          Text('通用交互层测试')
            .fontSize(28)
            .fontWeight(FontWeight.Bold);

          Text('用于验证卡片手势、弹层、自动保存、撤销通知、搜索遮罩和圆环绘制。')
            .fontSize(13)
            .fontColor('#475467');

          InteractableCard({
            leftHint: '左滑: 删除',
            rightHint: '右滑: 启动专注',
            onSwipeLeft: () => {
              this.undoVisible = true;
              this.pushLog('InteractableCard 左滑触发');
            },
            onSwipeRight: () => {
              this.pushLog('InteractableCard 右滑触发');
            }
          }) {
            Column({ space: 8 }) {
              Text('交互卡片手势测试')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('左右滑动达到阈值后触发回调。')
                .fontSize(12)
                .fontColor('#667085');
            }
            .alignItems(HorizontalAlign.Start);
          }

          Row({ space: 14 }) {
            CircleButton({
              icon: '+',
              text: '打开弹层',
              onTap: () => {
                this.actionSheetDialogController.open();
                this.pushLog('ActionSheet 打开');
              }
            });

            CircleButton({
              icon: '?',
              text: '搜索遮罩',
              fillColor: '#0369A1',
              onTap: () => {
                this.searchDialogController.open();
                this.pushLog('SearchOverlay 打开');
              }
            });

            CircleButton({
              icon: 'i',
              text: '详情卡片',
              fillColor: '#7C3AED',
              buttonSize: 52,
              onTap: () => {
                this.detailDialogController.open();
                this.pushLog('DetailCard 打开');
              }
            });

            CircleButton({
              icon: '-',
              text: '进度-15%',
              fillColor: '#15803D',
              buttonSize: 52,
              onTap: () => {
                this.decreaseProgress();
                this.pushLog('CircularProgress 更新到 ' + Math.round(this.progress * 100).toString() + '%');
              }
            });

            CircleButton({
              icon: '+',
              text: '进度+15%',
              fillColor: '#0F766E',
              buttonSize: 52,
              onTap: () => {
                this.cycleProgress();
                this.pushLog('CircularProgress 更新到 ' + Math.round(this.progress * 100).toString() + '%');
              }
            });
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween);

          CircularProgress({
            progress: this.progress,
            diameter: 160,
            strokeWidth: 10,
            progressColor: '#0EA5E9',
            trackColor: '#CBD5E1'
          });

          AutoSaveText({
            label: 'AutoSaveText 单组件测试',
            placeholder: '停止输入后自动保存',
            onAutoSave: (value: string) => {
              this.pushLog('AutoSaveText 自动保存: ' + value);
            }
          });

          Row({ space: 12 }) {
            Text('模拟键盘避让')
              .fontSize(13)
              .fontColor('#475467');

            Slider({ value: this.keyboardOffset, min: 0, max: 220, step: 10 })
              .layoutWeight(1)
              .onChange((value: number) => {
                this.keyboardOffset = value;
              });
          }
          .width('100%');

          Column({ space: 8 }) {
            Text('最近日志')
              .fontSize(14)
              .fontWeight(FontWeight.Medium);

            ForEach(this.logs, (item: string) => {
              Text('- ' + item)
                .fontSize(12)
                .fontColor('#475467')
                .width('100%');
            });

            if (this.logs.length === 0) {
              Text('暂无交互日志')
                .fontSize(12)
                .fontColor('#98A2B3');
            }
          }
          .width('100%')
          .padding(12)
          .borderRadius(14)
          .backgroundColor('#FFFFFF');
        }
        .alignItems(HorizontalAlign.Start)
        .padding(20);
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA');

      if (this.undoVisible) {
        UndoNotification({
          message: '已删除一条测试记录',
          actionText: '撤销',
          durationMs: 4000,
          onUndo: () => {
            this.pushLog('UndoNotification 执行撤销');
          },
          onTimeout: () => {
            this.pushLog('UndoNotification 倒计时结束');
          },
          onClose: () => {
            this.undoVisible = false;
          }
        })
          .margin({ left: 16, right: 16, bottom: 16 });
      }
    }
    .width('100%')
    .height('100%');
  }
}
