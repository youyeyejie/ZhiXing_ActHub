import { InteractableCard } from '../../components/card/InteractableCard';
import { DetailCard, DetailCardController } from '../../components/card/DetailCard';
import { ActionSheet, ActionSheetController } from '../../components/card/ActionSheet';
import { AutoSaveText } from '../../components/form/AutoSaveText';
import { EditableSuite } from '../../components/form/EditableSuite';
import { UndoNotification } from '../../components/feedback/UndoNotification';
import { AppOverlayRoute } from '../../app/AppConstants';
import { AppState, useAppState } from '../../app/AppStates';
import { ThemeMode } from '../../core/theme/ThemeManager';
import promptAction from '@ohos.promptAction';

/**
 * 通用交互抽象层测试页。
 * 使用组件化浮层测试遮罩、卡片和关闭交互。
 */
@ComponentV2
export struct SharedInteractionTestPage {
  @Local private app: AppState = useAppState();
  @Local private keyboardOffset: number = 0;
  @Local private undoVisible: boolean = false;
  @Local private progress: number = 0.45;
  @Local private logs: string[] = [];
  @Param actionSheetVisible: boolean = false;
  @Param detailCardVisible: boolean = false;
  @Param actionSheetController: ActionSheetController = new ActionSheetController();
  @Param detailCardController: DetailCardController = new DetailCardController();
  @Event onOpenActionSheet: () => void = () => {};
  @Event onCloseActionSheet: () => void = () => {};
  @Event onOpenDetailCard: () => void = () => {};
  @Event onCloseDetailCard: () => void = () => {};

  private pushLog(message: string): void {
    this.logs = [message, ...this.logs].slice(0, 6);
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
      panelHeight: '60%',
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
      isVisible: this.detailCardVisible,
      controller: this.detailCardController,
      content: this.buildDetailDialogContent,
      onDismiss: () => {
        this.onCloseDetailCard();
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
              this.onOpenDetailCard();
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
            Button('sheet')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.onOpenActionSheet();
                this.pushLog('ActionSheet 打开');
              });

            Button('search')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.app.nav.pushOverlayByName(AppOverlayRoute.SEARCH, this.app.nav.createSearchParam('todo', '搜索测试页'));
                this.pushLog('Search overlay route 打开');
              });

            Button('detail')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.onOpenDetailCard();
                this.pushLog('通过 DetailCard 组件打开详情卡片');
              });

            Button('toast')
              .type(ButtonType.Circle)
              .width(56)
              .height(56)
              .fontSize(24)
              .stateEffect(true)
              .backgroundColor(this.app.theme.palette.primary)
              .fontColor(this.app.theme.palette.surface)
              .onClick(() => {
                this.getUIContext().getPromptAction().showToast({
                  message: '这是一个通过 UIContext 调用的提示框。',
                  duration: 2000,
                  showMode: promptAction.ToastShowMode.DEFAULT,
                  bottom: 80
                })
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween);

          AutoSaveText({
            label: 'AutoSaveText 单组件测试',
            placeholder: '停止输入后自动保存',
            onAutoSave: (value: string) => {
              this.pushLog('AutoSaveText 自动保存: ' + value);
            }
          });
         
          Toggle({ type: ToggleType.Checkbox, isOn: false }).id('test-toggle')
            .onChange((value: boolean) => {
              this.pushLog('Toggle 组件状态: ' + (value ? 'ON' : 'OFF'));
            });
          Toggle({ type: ToggleType.Switch, isOn: false }).id('test-switch')
            .onChange((value: boolean) => {
              if (value) {
                this.app.theme.set(ThemeMode.DARK);
              } else {
                this.app.theme.set(ThemeMode.LIGHT);
              }
              this.pushLog('Toggle 组件状态: ' + (value ? 'ON' : 'OFF'));
            });

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

      if (this.detailCardVisible) {
        this.buildDetailDialog();
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
