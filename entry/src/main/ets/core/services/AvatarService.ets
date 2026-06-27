import { common } from '@kit.AbilityKit';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { UserAvatarCodec, UserAvatarConfig } from '../models/UserAvatar';

export class AvatarPickResult {
  success: boolean = false;
  message: string = '';
  avatar: string = '';

  constructor(success: boolean, message: string, avatar: string = '') {
    this.success = success;
    this.message = message;
    this.avatar = avatar;
  }
}

export class AvatarService {
  private readonly avatarDirName: string = 'avatars';
  private readonly maxAvatarBytes: number = 10 * 1024 * 1024;

  async pickAndSaveAvatar(
    context: common.UIAbilityContext,
    userId: number,
  ): Promise<AvatarPickResult> {
    const sourceUri: string | null = await this.pickSingleImage(context);
    if (sourceUri === null) {
      return new AvatarPickResult(false, '已取消选择头像');
    }

    if (!this.isLikelyImage(sourceUri)) {
      return new AvatarPickResult(false, '请选择 PNG、JPG 或 WebP 图片');
    }

    if (!this.isFileSizeAllowed(sourceUri)) {
      return new AvatarPickResult(false, '头像图片不能超过 10MB');
    }

    try {
      const targetPath: string = this.copyAvatarIntoApp(context, sourceUri, userId);
      const config: UserAvatarConfig = new UserAvatarConfig();
      config.kind = 'image';
      config.path = targetPath;
      config.scale = 1;
      config.offsetX = 0;
      config.offsetY = 0;
      return new AvatarPickResult(true, '已选择头像，可继续调整裁切区域', UserAvatarCodec.encode(config));
    } catch (_error) {
      return new AvatarPickResult(false, '保存头像失败，请重试');
    }
  }

  private async pickSingleImage(context: common.UIAbilityContext): Promise<string | null> {
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.png', '.jpg', '.jpeg', '.webp'];
      const documentPicker = new picker.DocumentViewPicker(context);
      const result: Array<string> = await documentPicker.select(options);
      return result.length > 0 ? result[0] : null;
    } catch (_error) {
      return null;
    }
  }

  private isLikelyImage(uri: string): boolean {
    const normalized: string = `${uri}`.toLowerCase();
    return normalized.endsWith('.png') ||
      normalized.endsWith('.jpg') ||
      normalized.endsWith('.jpeg') ||
      normalized.endsWith('.webp') ||
      normalized.indexOf('image') >= 0;
  }

  private isFileSizeAllowed(uri: string): boolean {
    try {
      const stat = fs.statSync(uri);
      return stat.size <= this.maxAvatarBytes;
    } catch (_error) {
      return true;
    }
  }

  private copyAvatarIntoApp(context: common.UIAbilityContext, sourceUri: string, userId: number): string {
    const avatarDir: string = `${context.filesDir}/${this.avatarDirName}`;
    try {
      fs.mkdirSync(avatarDir, true);
    } catch (_error) {
    }

    const targetPath: string = `${avatarDir}/user_${userId}_${Date.now()}${this.resolveExtension(sourceUri)}`;
    let sourceFile: fs.File | null = null;
    try {
      sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(sourceFile.fd, targetPath);
      return targetPath;
    } finally {
      if (sourceFile !== null) {
        fs.closeSync(sourceFile);
      }
    }
  }

  private resolveExtension(uri: string): string {
    const normalized: string = `${uri}`.toLowerCase();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return '.jpg';
    }
    if (normalized.endsWith('.webp')) {
      return '.webp';
    }
    return '.png';
  }
}
