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

class IcsRecurrenceRule {
  freq: string = '';
  until: string = '';
  count: number = 0;
  interval: number = 1;
  byDay: string[] = [];
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
        const plans: Array<Plan> = this.mapIcsItemToCoursePlans(icsFile.items[index]);
        for (let planIndex = 0; planIndex < plans.length; planIndex++) {
          const plan: Plan = plans[planIndex];
          const key: string = this.buildPlanDuplicateKey(plan);
          if (existingKeys.indexOf(key) >= 0) {
            continue;
          }
          await this.planRepository.insert(plan);
          existingKeys.push(key);
          importedCount += 1;
        }
      }

      await usePlanPageState().refreshAll();

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

  private mapIcsItemToCoursePlans(item: IcsItem): Array<Plan> {
    const startTime: number = this.parseIcsDateTime(item.dtStart);
    if (startTime <= 0) {
      return [];
    }

    let endTime: number = this.parseIcsDateTime(item.dtEnd);
    if (endTime <= startTime) {
      endTime = startTime + 60 * 60 * 1000;
    }

    const recurrenceRule: IcsRecurrenceRule | null = this.parseIcsRecurrenceRule(item);
    const occurrences: Array<number> = recurrenceRule === null
      ? [startTime]
      : this.expandRecurrenceStarts(startTime, recurrenceRule);
    if (occurrences.length === 0) {
      occurrences.push(startTime);
    }

    const duration: number = endTime - startTime;
    const now: number = Date.now();
    const plans: Array<Plan> = [];
    for (let index = 0; index < occurrences.length; index++) {
      const occurrenceStart: number = occurrences[index];
      const plan = new Plan();
      plan.content = item.summary.trim().length > 0 ? item.summary.trim() : '未命名课程';
      plan.timestamp = occurrenceStart;
      plan.startTime = occurrenceStart;
      plan.endTime = occurrenceStart + duration;
      plan.duration = duration;
      plan.location = item.location.trim();
      plan.isCourse = 1;
      plan.description = item.description.trim();
      plan.loopRule = recurrenceRule === null ? '' : this.buildPlanLoopRule(recurrenceRule);
      plan.reminderId = 0;
      plan.enableRemind = 0;
      plan.createdAt = now;
      plan.updatedAt = now;
      plans.push(plan);
    }
    return plans;
  }

  private parseIcsRecurrenceRule(item: IcsItem): IcsRecurrenceRule | null {
    for (let index = 0; index < item.properties.length; index++) {
      const property = item.properties[index];
      if (property.name !== 'RRULE') {
        continue;
      }
      const rule = new IcsRecurrenceRule();
      const parts: string[] = property.value.split(';');
      for (let partIndex = 0; partIndex < parts.length; partIndex++) {
        const segment: string = parts[partIndex].trim();
        const equalIndex: number = segment.indexOf('=');
        if (equalIndex <= 0) {
          continue;
        }
        const key: string = segment.substring(0, equalIndex).trim().toUpperCase();
        const value: string = segment.substring(equalIndex + 1).trim();
        switch (key) {
          case 'FREQ':
            rule.freq = value.toUpperCase();
            break;
          case 'UNTIL':
            rule.until = value;
            break;
          case 'COUNT':
            const countValue: number = Number(value);
            rule.count = countValue > 0 ? countValue : 0;
            break;
          case 'INTERVAL':
            const intervalValue: number = Number(value);
            rule.interval = intervalValue > 0 ? intervalValue : 1;
            break;
          case 'BYDAY':
            rule.byDay = this.parseByDayCodes(value);
            break;
          default:
            break;
        }
      }
      return rule.freq.length > 0 ? rule : null;
    }
    return null;
  }

  private expandRecurrenceStarts(startTime: number, rule: IcsRecurrenceRule): Array<number> {
    switch (rule.freq) {
      case 'DAILY':
        return this.expandDailyStarts(startTime, rule);
      case 'WEEKLY':
        return this.expandWeeklyStarts(startTime, rule);
      case 'MONTHLY':
        return this.expandMonthlyStarts(startTime, rule);
      case 'YEARLY':
        return this.expandYearlyStarts(startTime, rule);
      default:
        return [startTime];
    }
  }

  private expandDailyStarts(startTime: number, rule: IcsRecurrenceRule): Array<number> {
    const results: Array<number> = [];
    const untilTime: number = this.resolveRecurrenceUntilTime(rule.until, startTime);
    const maxCount: number = this.resolveRecurrenceCountLimit(rule.count);
    const stepMs: number = rule.interval * 24 * 60 * 60 * 1000;
    let currentTime: number = startTime;
    while (results.length < maxCount && currentTime <= untilTime) {
      results.push(currentTime);
      currentTime += stepMs;
    }
    return results;
  }

  private expandWeeklyStarts(startTime: number, rule: IcsRecurrenceRule): Array<number> {
    const results: Array<number> = [];
    const untilTime: number = this.resolveRecurrenceUntilTime(rule.until, startTime);
    const maxCount: number = this.resolveRecurrenceCountLimit(rule.count);
    const byDayCodes: string[] = rule.byDay.length > 0 ? rule.byDay : [this.toIcsWeekdayCode(startTime)];
    const weekdayOffsets: number[] = this.resolveWeeklyOffsets(startTime, byDayCodes);
    const startDate: Date = new Date(startTime);
    const startWeekBaseTime: number = this.resolveWeekBaseTime(startDate);

    let weekIndex: number = 0;
    while (results.length < maxCount) {
      const weekBaseTime: number = startWeekBaseTime + weekIndex * rule.interval * 7 * 24 * 60 * 60 * 1000;
      let reachedBoundary: boolean = false;
      for (let offsetIndex = 0; offsetIndex < weekdayOffsets.length; offsetIndex++) {
        const occurrenceTime: number = weekBaseTime + weekdayOffsets[offsetIndex] * 24 * 60 * 60 * 1000 +
          this.resolveTimeOfDayOffset(startDate);
        if (occurrenceTime < startTime) {
          continue;
        }
        if (occurrenceTime > untilTime) {
          reachedBoundary = true;
          continue;
        }
        results.push(occurrenceTime);
        if (results.length >= maxCount) {
          return results;
        }
      }
      if (reachedBoundary && weekBaseTime > untilTime) {
        break;
      }
      if (weekBaseTime > untilTime) {
        break;
      }
      weekIndex += 1;
    }
    return results;
  }

  private expandMonthlyStarts(startTime: number, rule: IcsRecurrenceRule): Array<number> {
    const results: Array<number> = [];
    const untilTime: number = this.resolveRecurrenceUntilTime(rule.until, startTime);
    const maxCount: number = this.resolveRecurrenceCountLimit(rule.count);
    let occurrenceIndex: number = 0;
    while (results.length < maxCount) {
      const currentDate: Date = new Date(startTime);
      currentDate.setMonth(currentDate.getMonth() + occurrenceIndex * rule.interval);
      const occurrenceTime: number = currentDate.getTime();
      if (occurrenceTime > untilTime) {
        break;
      }
      results.push(occurrenceTime);
      occurrenceIndex += 1;
    }
    return results;
  }

  private expandYearlyStarts(startTime: number, rule: IcsRecurrenceRule): Array<number> {
    const results: Array<number> = [];
    const untilTime: number = this.resolveRecurrenceUntilTime(rule.until, startTime);
    const maxCount: number = this.resolveRecurrenceCountLimit(rule.count);
    let occurrenceIndex: number = 0;
    while (results.length < maxCount) {
      const currentDate: Date = new Date(startTime);
      currentDate.setFullYear(currentDate.getFullYear() + occurrenceIndex * rule.interval);
      const occurrenceTime: number = currentDate.getTime();
      if (occurrenceTime > untilTime) {
        break;
      }
      results.push(occurrenceTime);
      occurrenceIndex += 1;
    }
    return results;
  }

  private resolveRecurrenceUntilTime(until: string, fallbackStartTime: number): number {
    if (until.trim().length === 0) {
      return Number.MAX_SAFE_INTEGER;
    }

    const normalized: string = until.trim();
    if (normalized.length === 8) {
      const dayEndTime: number = this.parseIcsDateTime(`${normalized}T235959`);
      return dayEndTime > 0 ? dayEndTime : fallbackStartTime;
    }

    const parsedTime: number = this.parseIcsDateTime(normalized);
    return parsedTime > 0 ? parsedTime : fallbackStartTime;
  }

  private resolveRecurrenceCountLimit(count: number): number {
    if (count > 0) {
      return count;
    }
    return 1000;
  }

  private resolveWeeklyOffsets(startTime: number, byDayCodes: string[]): Array<number> {
    const offsets: Array<number> = [];
    for (let index = 0; index < byDayCodes.length; index++) {
      const offset: number = this.toWeekOffset(byDayCodes[index]);
      if (offset < 0 || offsets.indexOf(offset) >= 0) {
        continue;
      }
      offsets.push(offset);
    }
    if (offsets.length === 0) {
      offsets.push(this.toWeekOffset(this.toIcsWeekdayCode(startTime)));
    }
    offsets.sort((left: number, right: number) => left - right);
    return offsets;
  }

  private resolveWeekBaseTime(date: Date): number {
    const normalized: Date = new Date(date.getTime());
    const weekday: number = normalized.getDay();
    const sundayOffset: number = weekday === 0 ? 0 : weekday;
    normalized.setDate(normalized.getDate() - sundayOffset);
    normalized.setHours(0, 0, 0, 0);
    return normalized.getTime();
  }

  private resolveTimeOfDayOffset(date: Date): number {
    return date.getHours() * 60 * 60 * 1000 +
      date.getMinutes() * 60 * 1000 +
      date.getSeconds() * 1000 +
      date.getMilliseconds();
  }

  private toWeekOffset(byDayCode: string): number {
    switch (byDayCode) {
      case 'SU':
        return 0;
      case 'MO':
        return 1;
      case 'TU':
        return 2;
      case 'WE':
        return 3;
      case 'TH':
        return 4;
      case 'FR':
        return 5;
      case 'SA':
        return 6;
      default:
        return -1;
    }
  }

  private toIcsWeekdayCode(timestamp: number): string {
    switch (new Date(timestamp).getDay()) {
      case 0:
        return 'SU';
      case 1:
        return 'MO';
      case 2:
        return 'TU';
      case 3:
        return 'WE';
      case 4:
        return 'TH';
      case 5:
        return 'FR';
      case 6:
        return 'SA';
      default:
        return 'MO';
    }
  }

  private buildPlanLoopRule(rule: IcsRecurrenceRule): string {
    const parts: string[] = [`FREQ=${rule.freq}`];
    if (rule.interval > 1) {
      parts.push(`INTERVAL=${rule.interval}`);
    }
    if (rule.byDay.length > 0) {
      parts.push(`BYDAY=${rule.byDay.join(',')}`);
    }
    if (rule.until.length > 0) {
      parts.push(`UNTIL=${rule.until}`);
    }
    if (rule.count > 0) {
      parts.push(`COUNT=${rule.count}`);
    }
    return parts.join(';');
  }

  private parseByDayCodes(value: string): Array<string> {
    const result: Array<string> = [];
    const rawValues: Array<string> = value.split(',');
    for (let index = 0; index < rawValues.length; index++) {
      const dayCode: string = rawValues[index].trim().toUpperCase();
      if (dayCode.length === 0) {
        continue;
      }
      result.push(dayCode);
    }
    return result;
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
