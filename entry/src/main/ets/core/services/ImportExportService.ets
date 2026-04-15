import { common, Want } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs, picker, ReadOptions, WriteOptions } from '@kit.CoreFileKit';
import { AppState } from '../../app/AppStates';
import { UserDatabase } from '../database/UserDatabase';
import { Plan } from '../models/Plan';
import { PlanRepository } from '../repositories/PlanRepository';
import { IcsFile, IcsItem, IcsService } from './IcsService';
import { usePlanPageState } from '../../pages/plan/PlanPageState';
import { useTodoPageState } from '../../pages/todo/TodoPageState';
import { useIdeaPageState } from '../../pages/idea/IdeaPageState';

const CHUNK_SIZE = 4096;

export class ImportExportResult {
  success: boolean = false;
  message: string = '';

  constructor(success: boolean, message: string) {
    this.success = success;
    this.message = message;
  }
}

export class ImportExportService {
  private icsService: IcsService = new IcsService();
  private planRepository: PlanRepository = new PlanRepository();

  async importUserData(context: common.UIAbilityContext, app: AppState): Promise<ImportExportResult> {
    const user = app.currentUser;
    if (user === null) {
      return new ImportExportResult(false, '当前未登录，无法导入用户数据');
    }

    const sourceUri: string | null = await this.pickSingleFile(context);
    if (sourceUri === null) {
      return new ImportExportResult(false, '已取消导入用户数据');
    }

    const account: string = user.name;
    if (account.trim().length === 0) {
      return new ImportExportResult(false, '当前账号信息不完整，无法导入');
    }

    const dbPath: string = await UserDatabase.getInstance().resolveDatabaseFilePath(context, account);

    try {
      await this.reopenCurrentUserDatabase(context, account, false);
      this.removeSqliteSidecarFiles(dbPath);
      this.copyFileUriToPath(sourceUri, dbPath);
      await this.reopenCurrentUserDatabase(context, account, true);
      this.resetPageStatesForReload();
      await this.restartApplication(context);
      return new ImportExportResult(true, '用户数据导入成功');
    } catch (error) {
      this.logBusinessError('importUserData failed', error);
      try {
        await this.reopenCurrentUserDatabase(context, account, true);
      } catch (_innerError) {}
      this.showError('导入用户数据失败', error);
      return new ImportExportResult(false, '用户数据导入失败');
    }
  }

  async exportUserData(context: common.UIAbilityContext, app: AppState): Promise<ImportExportResult> {
    const user = app.currentUser;
    if (user === null) {
      return new ImportExportResult(false, '当前未登录，无法导出用户数据');
    }

    const account: string = user.name;
    const targetUri: string | null = await this.pickSaveFile(context, `${user.name}_acthub.db`, ['SQLite|db']);
    if (targetUri === null) {
      return new ImportExportResult(false, '已取消导出用户数据');
    }

    try {
      const dbPath: string = await UserDatabase.getInstance().resolveDatabaseFilePath(context, account);
      await this.reopenCurrentUserDatabase(context, account, false);
      await this.yieldToPickerDismiss();
      this.copyPathToFileUri(dbPath, targetUri);
      await this.reopenCurrentUserDatabase(context, account, true);
      return new ImportExportResult(true, '用户数据导出成功');
    } catch (error) {
      try {
        await this.reopenCurrentUserDatabase(context, account, true);
      } catch (_innerError) {}
      this.logBusinessError('exportUserData failed', error);
      this.showError('导出用户数据失败', error);
      return new ImportExportResult(false, '用户数据导出失败');
    }
  }

  async importCourseIcs(context: common.UIAbilityContext, app: AppState): Promise<ImportExportResult> {
    if (!app.isLoggedIn) {
      return new ImportExportResult(false, '当前未登录，无法导入 ICS');
    }

    const sourceUri: string | null = await this.pickSingleFile(context);
    if (sourceUri === null) {
      return new ImportExportResult(false, '已取消导入 ICS');
    }

    let file: fs.File | null = null;
    try {
      file = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
      const icsFile: IcsFile = this.icsService.fromIcs(file);
      const existing: Array<Plan> = await this.planRepository.findAll();
      const existingKeys: Array<string> = [];
      for (let index = 0; index < existing.length; index++) {
        existingKeys.push(this.buildPlanDuplicateKey(existing[index]));
      }

      let importedCount: number = 0;
      for (let index = 0; index < icsFile.items.length; index++) {
        const plan: Plan | null = this.mapIcsItemToCoursePlan(icsFile.items[index]);
        if (plan === null) {
          continue;
        }
        const key: string = this.buildPlanDuplicateKey(plan);
        if (existingKeys.indexOf(key) >= 0) {
          continue;
        }
        await this.planRepository.insert(plan);
        existingKeys.push(key);
        importedCount += 1;
      }

      return new ImportExportResult(true, `ICS 导入完成，新增 ${importedCount} 条课程`);
    } catch (error) {
      this.showError('导入 ICS 失败', error);
      return new ImportExportResult(false, 'ICS 导入失败');
    } finally {
      if (file !== null) {
        fs.closeSync(file);
      }
    }
  }

  async exportCourseIcs(context: common.UIAbilityContext, app: AppState): Promise<ImportExportResult> {
    if (!app.isLoggedIn) {
      return new ImportExportResult(false, '当前未登录，无法导出 ICS');
    }

    const targetUri: string | null = await this.pickSaveFile(context, 'courses.ics', ['iCalendar|ics']);
    if (targetUri === null) {
      return new ImportExportResult(false, '已取消导出 ICS');
    }

    let file: fs.File | null = null;
    try {
      const plans: Array<Plan> = await this.planRepository.findAll();
      const icsFile: IcsFile = new IcsFile();
      for (let index = 0; index < plans.length; index++) {
        if (plans[index].isCourse !== 1) {
          continue;
        }
        icsFile.items.push(this.mapPlanToIcsItem(plans[index]));
      }

      await this.yieldToPickerDismiss();
      file = fs.openSync(targetUri, fs.OpenMode.READ_WRITE);
      this.icsService.eventsToIcs(icsFile, file);
      return new ImportExportResult(true, `ICS 导出完成，共 ${icsFile.items.length} 条课程`);
    } catch (error) {
      this.showError('导出 ICS 失败', error);
      return new ImportExportResult(false, 'ICS 导出失败');
    } finally {
      if (file !== null) {
        fs.closeSync(file);
      }
    }
  }

  private async pickSingleFile(context: common.UIAbilityContext): Promise<string | null> {
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      const documentPicker = new picker.DocumentViewPicker(context);
      const result: Array<string> = await documentPicker.select(options);
      return result.length > 0 ? result[0] : null;
    } catch (_error) {
      return null;
    }
  }

  private async pickSaveFile(
    context: common.UIAbilityContext,
    fileName: string,
    suffixChoices: Array<string>
  ): Promise<string | null> {
    try {
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [fileName];
      options.fileSuffixChoices = suffixChoices;
      const documentPicker = new picker.DocumentViewPicker(context);
      const result: Array<string> = await documentPicker.save(options);
      return result.length > 0 ? result[0] : null;
    } catch (error) {
      this.logBusinessError('pickSaveFile failed', error);
      return null;
    }
  }

  private copyFileUriToPath(sourceUri: string, destinationPath: string): void {
    let sourceFile: fs.File | null = null;
    try {
      sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(sourceFile.fd, destinationPath);
    } catch (error) {
      this.logBusinessError('copyFileUriToPath failed', error);
      throw new Error(this.stringifyError(error));
    } finally {
      if (sourceFile !== null) {
        fs.closeSync(sourceFile);
      }
    }
  }

  private copyPathToFileUri(sourcePath: string, destinationUri: string): void {
    let sourceFile: fs.File | null = null;
    let destinationFile: fs.File | null = null;
    try {
      sourceFile = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
    } catch (error) {
      this.logBusinessError('copyPathToFileUri source open failed', error);
      throw new Error(this.stringifyError(error));
    }

    try {
      destinationFile = fs.openSync(destinationUri, fs.OpenMode.READ_WRITE);
      this.copyOpenedFile(sourceFile, destinationFile);
    } catch (error) {
      this.logBusinessError('copyPathToFileUri target/copy failed', error);
      throw new Error(this.stringifyError(error));
    } finally {
      if (sourceFile !== null) {
        fs.closeSync(sourceFile);
      }
      if (destinationFile !== null) {
        fs.closeSync(destinationFile);
      }
    }
  }

  private copyOpenedFile(sourceFile: fs.File, destinationFile: fs.File): number {
    let readSize: number = 0;
    let writeOffset: number = 0;
    let readLength: number = 0;
    let totalBytes: number = 0;
    do {
      const chunk: ArrayBuffer = new ArrayBuffer(CHUNK_SIZE);
      const readOptions: ReadOptions = {
        offset: readSize,
        length: CHUNK_SIZE
      };
      readLength = fs.readSync(sourceFile.fd, chunk, readOptions);
      if (readLength > 0) {
        const writeOptions: WriteOptions = {
          offset: writeOffset,
          length: readLength
        };
        fs.writeSync(destinationFile.fd, chunk, writeOptions);
        readSize += readLength;
        writeOffset += readLength;
        totalBytes += readLength;
      }
    } while (readLength > 0);
    return totalBytes;
  }

  private mapIcsItemToCoursePlan(item: IcsItem): Plan | null {
    const startTime: number = this.parseIcsDateTime(item.dtStart);
    if (startTime <= 0) {
      return null;
    }

    let endTime: number = this.parseIcsDateTime(item.dtEnd);
    if (endTime <= startTime) {
      endTime = startTime + 60 * 60 * 1000;
    }

    const now: number = Date.now();
    const plan = new Plan();
    plan.content = item.summary.trim().length > 0 ? item.summary.trim() : '未命名课程';
    plan.timestamp = startTime;
    plan.startTime = startTime;
    plan.endTime = endTime;
    plan.duration = endTime - startTime;
    plan.location = item.location.trim();
    plan.isCourse = 1;
    plan.description = item.description.trim();
    plan.loopRule = '';
    plan.reminderId = 0;
    plan.enableRemind = 0;
    plan.createdAt = now;
    plan.updatedAt = now;
    return plan;
  }

  private mapPlanToIcsItem(plan: Plan): IcsItem {
    const item = new IcsItem();
    item.uid = this.buildPlanDuplicateKey(plan);
    item.dtStamp = this.formatIcsDateTime(Date.now());
    item.dtStart = this.formatIcsDateTime(plan.startTime);
    item.dtEnd = this.formatIcsDateTime(plan.endTime > plan.startTime ? plan.endTime : plan.startTime + 60 * 60 * 1000);
    item.summary = plan.content;
    item.description = plan.description;
    item.location = plan.location;
    item.categories = ['课程'];
    return item;
  }

  private parseIcsDateTime(value: string): number {
    const normalized: string = `${value}`.trim();
    if (normalized.length < 8) {
      return 0;
    }

    const isUtc: boolean = normalized.endsWith('Z');
    const compact: string = isUtc ? normalized.substring(0, normalized.length - 1) : normalized;
    const datePart: string = compact.substring(0, 8);
    const timePart: string = compact.length >= 15 ? compact.substring(9) : '';

    const year: number = Number(datePart.substring(0, 4));
    const month: number = Number(datePart.substring(4, 6));
    const day: number = Number(datePart.substring(6, 8));
    const hour: number = timePart.length >= 2 ? Number(timePart.substring(0, 2)) : 0;
    const minute: number = timePart.length >= 4 ? Number(timePart.substring(2, 4)) : 0;
    const second: number = timePart.length >= 6 ? Number(timePart.substring(4, 6)) : 0;

    if (isUtc) {
      return Date.UTC(year, month - 1, day, hour, minute, second);
    }
    return new Date(year, month - 1, day, hour, minute, second).getTime();
  }

  private formatIcsDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year: string = `${date.getFullYear()}`;
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    const hour: string = `${date.getHours()}`.padStart(2, '0');
    const minute: string = `${date.getMinutes()}`.padStart(2, '0');
    const second: string = `${date.getSeconds()}`.padStart(2, '0');
    return `${year}${month}${day}T${hour}${minute}${second}`;
  }

  private buildPlanDuplicateKey(plan: Plan): string {
    return [
      plan.content.trim(),
      `${plan.startTime}`,
      `${plan.endTime}`,
      plan.location.trim(),
      `${plan.isCourse === 1 ? 1 : 0}`
    ].join('|');
  }

  private showError(prefix: string, error: Object): void {
    let detail: string = '';
    const businessError: BusinessError = error as BusinessError;
    if (businessError !== undefined && businessError !== null) {
      detail = `${businessError.code}`;
    }
    try {
      promptAction.showToast({
        message: detail.length > 0 ? `${prefix}(${detail})` : prefix,
        duration: 1600
      });
    } catch (_toastError) {}
  }

  private logBusinessError(prefix: string, error: Object): void {
    void prefix;
    void error;
  }

  private stringifyError(error: Object): string {
    const businessError: BusinessError = error as BusinessError;
    if (businessError !== undefined && businessError !== null) {
      return `${businessError.code}:${businessError.message}`;
    }
    return JSON.stringify(error);
  }

  private removeSqliteSidecarFiles(dbPath: string): void {
    const walPath: string = dbPath + '-wal';
    const shmPath: string = dbPath + '-shm';
    this.removeFileIfExists(walPath, 'wal');
    this.removeFileIfExists(shmPath, 'shm');
  }

  private removeFileIfExists(path: string, label: string): void {
    try {
      fs.unlinkSync(path);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      if (businessError !== undefined && businessError !== null && businessError.code === 13900002) {
        return;
      }
      this.logBusinessError(`removeFileIfExists ${label} failed`, error);
    }
  }

  private yieldToPickerDismiss(): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, 0);
    });
  }

  private async reopenCurrentUserDatabase(
    context: common.UIAbilityContext,
    username: string,
    reopen: boolean
  ): Promise<void> {
    await UserDatabase.getInstance().close();
    if (reopen) {
      await UserDatabase.getInstance().initialize(context, username);
    }
  }

  private resetPageStatesForReload(): void {
    usePlanPageState().resetForReload();
    useTodoPageState().resetForReload();
    useIdeaPageState().resetForReload();
  }

  private restartApplication(context: common.UIAbilityContext): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (reason: Error) => void) => {
      try {
        const applicationContext = context.getApplicationContext();
        const want: Want = {
          bundleName: 'com.nis3366.ZhixingActhub',
          abilityName: 'EntryAbility'
        };
        applicationContext.restartApp(want);
        resolve();
      } catch (error) {
        reject(new Error(this.stringifyError(error)));
      }
    });
  }
}
