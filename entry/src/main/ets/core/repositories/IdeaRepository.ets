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

  /**
   * 按关键词搜索闪记（模糊匹配 title 和 content）。
   * @param keyword 搜索关键词
   * @returns 匹配的闪记列表
   */
  search(keyword: string): Promise<Idea[]> {
    if (!keyword || keyword.trim().length === 0) {
      return this.findAll();
    }
    const lowerKeyword = keyword.trim().toLowerCase();
    return this.findAll().then((ideas: Idea[]) => {
      return ideas.filter(
        (idea: Idea) =>
          idea.title.toLowerCase().includes(lowerKeyword) ||
          idea.content.toLowerCase().includes(lowerKeyword),
      );
    });
  }

  /**
   * 按时间范围查询闪记。
   * @param startTime 起始时间戳（闭区间）
   * @param endTime 结束时间戳（闭区间）
   * @returns 时间范围内的闪记列表
   */
  findByTimeRange(startTime: number, endTime: number): Promise<Idea[]> {
    return this.findAll().then((ideas: Idea[]) => {
      return ideas.filter((idea: Idea) => idea.timestamp >= startTime && idea.timestamp <= endTime);
    });
  }

  /**
   * 获取每日闪记创建数量统计（用于热力图）。
   * @param days 统计天数，默认 30 天
   * @returns 每日创建数量映射，key 为 YYYY-MM-DD 格式
   */
  getDailyCountMap(days: number = 30): Promise<Record<string, number>> {
    const now = Date.now();
    const startTime = now - days * 24 * 60 * 60 * 1000;
    return this.findAll().then((ideas: Idea[]) => {
      const countMap: Record<string, number> = {};
      ideas
        .filter((idea: Idea) => idea.timestamp >= startTime)
        .forEach((idea: Idea) => {
          const date = new Date(idea.timestamp);
          const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
          countMap[key] = (countMap[key] || 0) + 1;
        });
      return countMap;
    });
  }

  /**
   * 获取闪记总数。
   * @returns 闪记总数
   */
  getTotalCount(): Promise<number> {
    const all = this.query.find();
    return Promise.resolve(all.length);
  }

  /**
   * 获取闪记总字数。
   * @returns 总字数
   */
  getTotalLength(): Promise<number> {
    const all = this.query.find();
    const total = all.reduce((sum: number, idea: Idea) => sum + (idea.length || 0), 0);
    return Promise.resolve(total);
  }
}
