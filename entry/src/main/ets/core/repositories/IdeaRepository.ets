import { Idea } from "../models/Idea";
import { BaseRepository } from "./BaseRepository";

/**
 * 闪记仓储。
 * 提供闪记的 CRUD、搜索和热力图统计能力。
 */
export class IdeaRepository extends BaseRepository<Idea> {
  constructor() {
    super(Idea);
  }

  async getDailyCountMap(days: number): Promise<Record<string, number>> {
    const ideas: Array<Idea> = await this.findAll();
    const result: Record<string, number> = {};
    const dayRange: number = days > 0 ? days : 0;
    const now: number = Date.now();
    const startTime: number = dayRange > 0 ? now - (dayRange - 1) * 24 * 60 * 60 * 1000 : now;

    for (let i = 0; i < ideas.length; i++) {
      const idea: Idea = ideas[i];
      const createdAt: number = idea.createdAt > 0 ? idea.createdAt : idea.timestamp;
      if (dayRange > 0 && createdAt < startTime) {
        continue;
      }

      const dateKey: string = this.formatDateKey(createdAt);
      const currentCount: number = result[dateKey] ? result[dateKey] : 0;
      result[dateKey] = currentCount + 1;
    }

    return result;
  }

  async getTotalCount(): Promise<number> {
    const ideas: Array<Idea> = await this.findAll();
    return ideas.length;
  }

  async getTotalLength(): Promise<number> {
    const ideas: Array<Idea> = await this.findAll();
    let totalLength: number = 0;

    for (let i = 0; i < ideas.length; i++) {
      totalLength += ideas[i].length;
    }

    return totalLength;
  }

  private formatDateKey(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const month: string = String(date.getMonth() + 1).padStart(2, "0");
    const day: string = String(date.getDate()).padStart(2, "0");
    return `${date.getFullYear()}-${month}-${day}`;
  }
}
