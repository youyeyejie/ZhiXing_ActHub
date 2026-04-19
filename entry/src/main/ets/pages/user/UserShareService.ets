import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { systemShare } from '@kit.ShareKit';

/**
 * user 页分享服务。
 * 负责将目标组件截图导出为图片，并通过 systemShare 拉起系统分享面板。
 */
export class UserShareService {
  private readonly shareImageDir: string = 'share';
  private readonly shareImageName: string = 'user-page-share.png';

  async shareSnapshot(
    uiContext: UIContext,
    snapshotId: string,
    onToast: (message: string) => void,
  ): Promise<void> {
    try {
      const context: common.UIAbilityContext | null = this.getAbilityContext(uiContext);
      if (context === null) {
        onToast('当前无法拉起系统分享');
        return;
      }

      const snapshot = await uiContext.getComponentSnapshot().get(snapshotId, {
        scale: 2,
        waitUntilRenderFinished: true,
      });
      const shareImagePath: string = await this.writeSnapshotToShareFile(context, snapshot);
      await this.showSystemSharePanel(context, fileUri.getUriFromPath(shareImagePath), onToast);
    } catch (_error) {
      onToast('生成或分享图片失败，请稍后重试');
    }
  }

  private getAbilityContext(uiContext: UIContext): common.UIAbilityContext | null {
    try {
      return uiContext.getHostContext() as common.UIAbilityContext;
    } catch (_error) {
      return null;
    }
  }

  private ensureShareDirectory(context: common.UIAbilityContext): string {
    const shareDir: string = `${context.cacheDir}/${this.shareImageDir}`;
    try {
      fs.mkdirSync(shareDir, true);
    } catch (_error) {
    }
    return shareDir;
  }

  private buildShareImagePath(context: common.UIAbilityContext): string {
    return `${this.ensureShareDirectory(context)}/${this.shareImageName}`;
  }

  private async writeSnapshotToShareFile(
    context: common.UIAbilityContext,
    snapshot: image.PixelMap,
  ): Promise<string> {
    const targetPath: string = this.buildShareImagePath(context);
    let file: fs.File | null = null;
    const packer: image.ImagePacker = image.createImagePacker();
    try {
      file = await fs.open(
        targetPath,
        fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC,
      );
      await packer.packToFile(snapshot, file.fd, {
        format: 'image/png',
        quality: 100,
      });
      return targetPath;
    } finally {
      if (file !== null) {
        fs.closeSync(file);
      }
      await packer.release();
    }
  }

  private async showSystemSharePanel(
    context: common.UIAbilityContext,
    imageUri: string,
    onToast: (message: string) => void,
  ): Promise<void> {
    const shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PNG,
      uri: imageUri,
      title: '知行 ActHub 我的页分享图',
      description: '可在系统分享面板中发送或保存到相册',
    });
    const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    const onShareCompleted = (result: systemShare.ShareOperationResult): void => {
      if (result.targetAbilityInfo.name === systemShare.ShareAbilityName.SAVE_TO_MEDIA_ASSET) {
        onToast('分享图已交给系统保存到相册');
        return;
      }
      onToast('分享图已发送到所选渠道');
    };
    const onDismiss = (): void => {
      controller.off('shareCompleted', onShareCompleted);
      controller.off('dismiss', onDismiss);
    };

    controller.on('shareCompleted', onShareCompleted);
    controller.on('dismiss', onDismiss);
    await controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL,
    });
  }
}
