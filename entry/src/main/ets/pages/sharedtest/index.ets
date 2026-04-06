import { CircleButton } from '../../components/buttons/CircleButton';
import { InteractableCard } from '../../components/card/InteractableCard';
import { DetailCard } from '../../components/card/DetailCard';
import { ActionSheet, ActionSheetController } from '../../components/overlays/ActionSheet';
import { AutoSaveText } from '../../components/form/AutoSaveText';
import { EditableSuite } from '../../components/form/EditableSuite';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { CircularProgress } from '../../components/progress/CircularProgress';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { ThemeMode } from '../../core/theme/ThemeManager';

/**
 * 通用交互抽象层测试页。
 * 使用 CustomDialog 打开窗口级浮层，确保可覆盖 TabBar。
 */
@ComponentV2
export struct SharedInteractionTestPage {
  @Local private app: AppState = useAppState();
  @Local private keyboardOffset: number = 0;
  @Local private undoVisible: boolean = false;
  @Local private progress: number = 0.45;
  @Local private logs: string[] = [];
  @Param actionSheetVisible: boolean = false;
  @Param actionSheetController: ActionSheetController = new ActionSheetController();
  @Event onOpenActionSheet: () => void = () => {};
  @Event onCloseActionSheet: () => void = () => {};

  private detailDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildDetailDialog,
    customStyle: true,
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

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
  private buildActionSheetContent() {
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
          this.actionSheetController.dismiss();
        });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private buildActionSheet() {
    ActionSheet({
      isVisible: this.actionSheetVisible,
      panelHeight: '70%',
      keyboardOffset: this.keyboardOffset,
      controller: this.actionSheetController,
      onDismiss: () => {
        this.onCloseActionSheet();
      }
    }) {
      this.buildActionSheetContent();
    }
  }

  @Builder
  private buildDetailDialogContent() {
    Column({ space: 10 }) {
      Text('详情卡片基础组件')
        .fontSize(18)
        .fontWeight(FontWeight.Bold);
      Text('宽度 80%，高度 60%，支持背景遮罩和右上角关闭。')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);
      Text('你可以在这里放详情展示、编辑表单或操作按钮。')
        .fontSize(13)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private buildDetailDialog() {
    DetailCard({
      controller: this.detailDialogController,
      content: this.buildDetailDialogContent,
      onClose: () => {
        this.pushLog('DetailCard 已关闭');
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: 16 }) {
          Text('通用交互层测试')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.app.theme.palette.textPrimary);

          Text('用于验证卡片手势、弹层、自动保存、撤销通知、搜索遮罩和圆环绘制。')
            .fontSize(13)
            .fontColor(this.app.theme.palette.textSecondary);

          Row({ space: 8 }) {
            Button('浅色')
              .fontSize(12)
              .fontColor(this.app.theme.palette.surface)
              .backgroundColor(this.app.theme.palette.primary)
              .onClick(() => {
                this.app.theme.set(ThemeMode.LIGHT);
                this.pushLog('主题切换: LIGHT');
              });

            Button('深色')
              .fontSize(12)
              .fontColor(this.app.theme.palette.surface)
              .backgroundColor(this.app.theme.palette.primary)
              .onClick(() => {
                this.app.theme.set(ThemeMode.DARK);
                this.pushLog('主题切换: DARK');
              });
          }
          .width('100%');

          InteractableCard({
            leftHint: '左滑: 删除',
            rightHint: '右滑: 启动专注',
            enableSwipeLeft: true,
            enableSwipeRight: false,
            onSwipeLeft: () => {
              this.undoVisible = true;
              this.pushLog('InteractableCard 左滑触发');
            },
            onSwipeRight: () => {
              this.pushLog('InteractableCard 右滑触发');
            },
            onCardTap: () => {
              this.detailDialogController.open();
              this.pushLog('InteractableCard 点击打开详情卡片');
            }
          }) {
            Column({ space: 8 }) {
              Text('交互卡片手势测试')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('左右滑动达到阈值后触发回调。')
                .fontSize(12)
                .fontColor(this.app.theme.palette.textSecondary);
            }
            .alignItems(HorizontalAlign.Start);
          }

          Row({ space: 14 }) {
            CircleButton({
              icon: '+',
              text: '打开弹层',
              onTap: () => {
                this.onOpenActionSheet();
                this.pushLog('ActionSheet 打开');
              }
            });

            CircleButton({
              icon: '?',
              text: '搜索遮罩',
              fillColor: this.app.theme.palette.primary,
              onTap: () => {
                this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索测试页'));
                this.pushLog('Search overlay route 打开');
              }
            });

            CircleButton({
              icon: 'i',
              text: '详情卡片',
              fillColor: this.app.theme.palette.primary,
              buttonSize: 52,
              onTap: () => {
                this.detailDialogController.open();
                this.pushLog('通过 CustomDialog 打开详情卡片');
              }
            });

            CircleButton({
              icon: '-',
              text: '进度-15%',
              fillColor: this.app.theme.palette.primary,
              buttonSize: 52,
              onTap: () => {
                this.decreaseProgress();
                this.pushLog('CircularProgress 更新到 ' + Math.round(this.progress * 100).toString() + '%');
              }
            });

            CircleButton({
              icon: '+',
              text: '进度+15%',
              fillColor: this.app.theme.palette.primary,
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
            strokeWidth: 10
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
              .fontColor(this.app.theme.palette.textSecondary);

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
                .fontColor(this.app.theme.palette.textSecondary)
                .width('100%');
            });

            if (this.logs.length === 0) {
              Text('暂无交互日志')
                .fontSize(12)
                .fontColor(this.app.theme.palette.textTertiary);
            }
          }
          .width('100%')
          .padding(12)
          .borderRadius(14)
          .backgroundColor(this.app.theme.palette.surface);
        }
        .alignItems(HorizontalAlign.Start)
        .padding(20);
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.app.theme.palette.background);

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

      if (this.actionSheetVisible) {
        this.buildActionSheet();
      }
    }
    .width('100%')
    .height('100%');
  }
}

@Builder
export function SharedInteractionTestPageBuilder(_name: string, _param: Object) {
  SharedInteractionTestPage();
}
