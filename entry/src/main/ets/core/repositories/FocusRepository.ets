import { Focus } from '../models/Focus';
import { BaseRepository } from './BaseRepository';

export class FocusRepository extends BaseRepository<Focus> {
  constructor() {
    super(Focus);
  }

  async insertFocusRecord(focus: Focus): Promise<boolean> {
    try {
      await this.save(focus);
      return true;
    } catch (_error) {
      return false;
    }
  }

  async getDailyDurationMap(days: number): Promise<Record<string, number>> {
    const records: Array<Focus> = await this.findAll();
    const result: Record<string, number> = {};
    const safeDays: number = days > 0 ? days : 0;
    const now: number = Date.now();
    const startTime: number = safeDays > 0 ? now - (safeDays - 1) * 24 * 60 * 60 * 1000 : now;

    for (let index = 0; index < records.length; index++) {
      const focus: Focus = records[index];
      const timestamp: number = focus.startTime > 0 ? focus.startTime : focus.timestamp;
      if (safeDays > 0 && timestamp < startTime) {
        continue;
      }

      const dateKey: string = this.formatDateKey(timestamp);
      const currentValue: number = result[dateKey] ? result[dateKey] : 0;
      result[dateKey] = currentValue + Math.max(0, focus.duration);
    }

    return result;
  }

  async getTotalCount(): Promise<number> {
    const records: Array<Focus> = await this.findAll();
    return records.length;
  }

  async getTotalDuration(): Promise<number> {
    const records: Array<Focus> = await this.findAll();
    let totalDuration: number = 0;

    for (let index = 0; index < records.length; index++) {
      totalDuration += Math.max(0, records[index].duration);
    }

    return totalDuration;
  }

  private formatDateKey(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }
}
