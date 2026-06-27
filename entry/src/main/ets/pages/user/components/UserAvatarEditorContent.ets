import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import promptAction from '@ohos.promptAction';
import { AppState, useAppState } from '../../../app/AppStates';
import { UserAvatarCodec, UserAvatarConfig } from '../../../core/models/UserAvatar';
import { AvatarPickResult, AvatarService } from '../../../core/services/AvatarService';
import { FormTypography } from '../../../core/theme/FormTypography';

@ComponentV2
export struct UserAvatarEditorContent {
  @Local private app: AppState = useAppState();
  @Local private avatarDraft: string = '';
  @Local private saving: boolean = false;
  @Local private panStartOffsetX: number = 0;
  @Local private panStartOffsetY: number = 0;
  @Local private pinchStartScale: number = 1;
  private avatarService: AvatarService = new AvatarService();

  aboutToAppear(): void {
    this.avatarDraft = this.app.currentUserAvatar;
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 1600 });
    } catch (_error) {}
  }

  private resolveConfig(): UserAvatarConfig {
    return UserAvatarCodec.decode(this.avatarDraft);
  }

  private updateScale(value: number): void {
    const config: UserAvatarConfig = this.resolveConfig();
    config.scale = UserAvatarCodec.normalizeScale(value);
    this.avatarDraft = UserAvatarCodec.encode(config);
  }

  private updateOffsetX(value: number): void {
    const config: UserAvatarConfig = this.resolveConfig();
    config.offsetX = UserAvatarCodec.normalizeOffset(value);
    this.avatarDraft = UserAvatarCodec.encode(config);
  }

  private updateOffsetY(value: number): void {
    const config: UserAvatarConfig = this.resolveConfig();
    config.offsetY = UserAvatarCodec.normalizeOffset(value);
    this.avatarDraft = UserAvatarCodec.encode(config);
  }

  private resolveImageUri(config: UserAvatarConfig): string {
    try {
      return fileUri.getUriFromPath(config.path);
    } catch (_error) {
      return config.path;
    }
  }

  private beginPan(): void {
    const config: UserAvatarConfig = this.resolveConfig();
    this.panStartOffsetX = config.offsetX;
    this.panStartOffsetY = config.offsetY;
  }

  private updatePan(offsetX: number, offsetY: number): void {
    const config: UserAvatarConfig = this.resolveConfig();
    config.offsetX = UserAvatarCodec.normalizeOffset(this.panStartOffsetX + offsetX / 3.2);
    config.offsetY = UserAvatarCodec.normalizeOffset(this.panStartOffsetY + offsetY / 3.2);
    this.avatarDraft = UserAvatarCodec.encode(config);
  }

  private beginPinch(): void {
    this.pinchStartScale = this.resolveConfig().scale;
  }

  private updatePinch(scale: number): void {
    const config: UserAvatarConfig = this.resolveConfig();
    config.scale = UserAvatarCodec.normalizeScale(this.pinchStartScale * scale);
    this.avatarDraft = UserAvatarCodec.encode(config);
  }

  private async chooseAvatar(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const result: AvatarPickResult = await this.avatarService.pickAndSaveAvatar(context, this.app.currentUserId);
    if (result.success) {
      this.avatarDraft = result.avatar;
    }
  }

  private async saveAvatar(): Promise<void> {
    if (this.saving) {
      return;
    }

    this.saving = true;
    try {
      const result = await this.app.updateCurrentUserAvatar(this.avatarDraft);
      this.safeToast(result.message);
      if (result.success) {
        this.app.nav.back(false);
      }
    } finally {
      this.saving = false;
    }
  }

  @Builder
  private buildEditableImage() {
    if (this.resolveConfig().kind === 'image') {
      Image(this.resolveImageUri(this.resolveConfig()))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .scale({
          x: this.resolveConfig().scale,
          y: this.resolveConfig().scale,
        })
        .translate({
          x: `${this.resolveConfig().offsetX}%`,
          y: `${this.resolveConfig().offsetY}%`,
        })
    } else {
      Image($r('app.media.avatar_default'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
    }
  }

  @Builder
  private buildCropCanvas() {
    Stack({ alignContent: Alignment.Center }) {
      this.buildEditableImage()

      Row()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')

      Stack() {
        this.buildEditableImage()
      }
      .width('100%')
      .height('100%')
      .borderRadius(9999)
      .clip(true)

      Circle()
        .width('100%')
        .height('100%')
        .fill(this.app.theme.palette.transparent)
        .stroke(this.app.theme.palette.surface)
        .strokeWidth(2)
        .shadow({ radius: 12, color: this.app.theme.palette.mask, offsetX: 0, offsetY: 0 })

      Row()
        .width('100%')
        .height('100%')
        .border({ width: 1, color: this.app.theme.palette.border })
    }
    .width('100%')
    .aspectRatio(1)
    .clip(true)
    .backgroundColor(this.app.theme.palette.surfaceSecondary)
    .gesture(
      GestureGroup(
        GestureMode.Parallel,
        PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
          .onActionStart((_event: GestureEvent) => {
            this.beginPan();
          })
          .onActionUpdate((event: GestureEvent) => {
            this.updatePan(event.offsetX, event.offsetY);
          }),
        PinchGesture({ fingers: 2, distance: 1 })
          .onActionStart((_event: GestureEvent) => {
            this.beginPinch();
          })
          .onActionUpdate((event: GestureEvent) => {
            this.updatePinch(event.scale);
          }),
      ),
    );
  }

  build() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Text('头像')
          .fontSize(FormTypography.TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
          .layoutWeight(1)
        Button('更换')
          .height(34)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textPrimary)
          .backgroundColor(this.app.theme.palette.surfaceSecondary)
          .borderRadius(999)
          .onClick(async () => {
            await this.chooseAvatar();
          })
        Button('保存')
          .height(34)
          .fontSize(12)
          .enabled(!this.saving)
          .fontColor(this.app.theme.palette.surface)
          .backgroundColor(this.app.theme.palette.primary)
          .borderRadius(999)
          .onClick(async () => {
            await this.saveAvatar();
          })
      }
      .width('100%')

      this.buildCropCanvas()
    }
    .width('100%');
  }
}
