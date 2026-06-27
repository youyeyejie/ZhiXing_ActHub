import { fileUri } from '@kit.CoreFileKit';
import { AppState, useAppState } from '../../../app/AppStates';
import { UserAvatarCodec, UserAvatarConfig } from '../../../core/models/UserAvatar';

@ComponentV2
export struct UserAvatarImage {
  @Local private app: AppState = useAppState();
  @Param avatar: string = '';
  @Param avatarSize: number = 58;
  @Param avatarRadius: number = 29;
  @Param showShadow: boolean = false;

  private resolveConfig(): UserAvatarConfig {
    return UserAvatarCodec.decode(this.avatar);
  }

  private resolveImageUri(config: UserAvatarConfig): string {
    try {
      return fileUri.getUriFromPath(config.path);
    } catch (_error) {
      return config.path;
    }
  }

  @Builder
  private buildAvatarSource() {
    if (this.resolveConfig().kind === 'image') {
      Image(this.resolveImageUri(this.resolveConfig()))
        .width(this.avatarSize)
        .height(this.avatarSize)
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
        .width(this.avatarSize)
        .height(this.avatarSize)
        .objectFit(ImageFit.Cover)
    }
  }

  build() {
    Stack() {
      this.buildAvatarSource()
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
    .borderRadius(this.avatarRadius)
    .clip(true)
    .backgroundColor(this.app.theme.palette.surfaceSecondary)
    .shadow({
      radius: this.showShadow ? 18 : 0,
      color: this.app.theme.palette.mask,
      offsetX: 0,
      offsetY: this.showShadow ? 8 : 0,
    });
  }
}
