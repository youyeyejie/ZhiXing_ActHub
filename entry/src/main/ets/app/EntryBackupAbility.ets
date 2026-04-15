import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

/**
 * 类功能简介：
 * - 应用备份扩展入口，预留备份与恢复流程。
 * - TODO: 尚未接入实际数据清单与版本迁移策略。
 *
 * 可传入项：
 * - `onRestore(bundleVersion)` 接收系统传入的包版本信息。
 *
 * 返回行为：
 * - 备份与恢复回调均返回 Promise。
 *
 * 副作用：
 * - 当前仅记录日志，无实际备份写入。
 */
export default class EntryBackupAbility extends BackupExtensionAbility {
  /**
   * 备份回调。
   * TODO: 后续写入实际备份文件与元信息。
   */
  async onBackup() {
    await Promise.resolve();
  }

  /**
   * 恢复回调。
   * TODO: 后续按版本恢复数据并处理兼容迁移。
   */
  async onRestore(bundleVersion: BundleVersion) {
    void bundleVersion;
    await Promise.resolve();
  }
}
