import { AppState, useAppState } from "../../../app/AppStates";
import { IdeaRepository } from "../../../core/repositories/IdeaRepository";
import { IdeaPageState, useIdeaPageState } from "../IdeaPageState";
import { Idea } from "../../../core/models/Idea";

/**
 * 热力图单日数据。
 */
interface HeatmapDay {
  date: string;
  count: number;
}

/**
 * 闪记活跃度热力图组件。
 * 根据每日创建数量显示颜色深浅的热力网格。
 */
@ComponentV2
export struct ActivityHeatmap {
  @Local private app: AppState = useAppState();
  @Local private state: IdeaPageState = useIdeaPageState();

  private repository: IdeaRepository = new IdeaRepository();
  @Local private countMap: Record<string, number> = {};
  @Local private totalCount: number = 0;
  @Local private totalLength: number = 0;
  @Local private loading: boolean = false;

  // 热力图配置
  private readonly CELL_WIDTH: number = 11;   // 单元格宽度
  private readonly CELL_HEIGHT: number = 11;  // 单元格高度
  private readonly CELL_GAP: number = 2;      // 格子间距
  private readonly WEEKS: number = 16;        // 显示 16 周数据

  aboutToAppear(): void {
    // 初始加载时从数据库获取最新数据
    this.loadStats();
  }

  /**
   * 从 state.ideas 计算每日统计（实时响应列表变化）。
   */
  private computeStatsFromIdeas(): void {
    const today = new Date();
    const startTime = today.getTime() - this.WEEKS * 7 * 24 * 60 * 60 * 1000;

    const countMap: Record<string, number> = {};
    let totalCount = 0;
    let totalLength = 0;

    this.state.ideas.forEach((idea: Idea) => {
      totalCount += 1;
      totalLength += idea.length || 0;

      if (idea.timestamp >= startTime) {
        const date = new Date(idea.timestamp);
        const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
        countMap[key] = (countMap[key] || 0) + 1;
      }
    });

    this.countMap = countMap;
    this.totalCount = totalCount;
    this.totalLength = totalLength;
  }

  /**
   * 加载统计数据（从数据库）。
   */
  private async loadStats(): Promise<void> {
    this.loading = true;
    try {
      this.countMap = await this.repository.getDailyCountMap(this.WEEKS * 7);
      this.totalCount = await this.repository.getTotalCount();
      this.totalLength = await this.repository.getTotalLength();
    } catch (_error) {
      // 忽略错误
    } finally {
      this.loading = false;
    }
  }

  /**
   * 获取热力图颜色。
   * 0 个 = 最浅，1-2 个 = 浅，3-5 个 = 中，6+ 个 = 深
   */
  private getHeatColor(count: number): string {
    if (count === 0) {
      return this.app.theme.palette.surfaceSecondary;
    }
    if (count <= 2) {
      return this.app.theme.palette.heatmapLow;
    }
    if (count <= 5) {
      return this.app.theme.palette.heatmapMedium;
    }
    return this.app.theme.palette.heatmapHigh;
  }

  /**
   * 生成热力图数据（按周分组，每周 7 天从周日到周六）。
   * 范围：从 (WEEKS-1) 周前的周日 到 本周六，覆盖包含今天在内的完整网格。
   */
  private generateHeatmapData(): HeatmapDay[][] {
    // 每次生成数据前，从 state.ideas 实时计算统计
    this.computeStatsFromIdeas();

    const weeks: HeatmapDay[][] = [];
    const today = new Date();
    // 起点：本周日再往前推 (WEEKS-1) 整周
    const startDate = new Date(today);
    startDate.setDate(today.getDate() - today.getDay() - (this.WEEKS - 1) * 7);

    for (let week = 0; week < this.WEEKS; week++) {
      const weekData: HeatmapDay[] = [];
      for (let day = 0; day < 7; day++) {
        const currentDate = new Date(startDate);
        currentDate.setDate(startDate.getDate() + week * 7 + day);
        const dateKey = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, "0")}-${String(currentDate.getDate()).padStart(2, "0")}`;
        const count = this.countMap[dateKey] || 0;
        weekData.push({ date: dateKey, count: count });
      }
      weeks.push(weekData);
    }
    return weeks;
  }

  /**
   * 格式化数字（万以下直接显示，万以上显示 X.X 万）。
   */
  private formatNumber(num: number): string {
    if (num >= 10000) {
      return (num / 10000).toFixed(1) + " 万";
    }
    return num.toString();
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text("活跃度")
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.app.theme.palette.textPrimary)
        Blank()
        Text(`${this.totalCount} 条笔记 · ${this.formatNumber(this.totalLength)} 字`)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary)
      }.width("100%")

      // 热力图网格
      if (this.loading) {
        Row() {
          Blank()
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.app.theme.palette.textTertiary)
          Blank()
        }
        .width("100%")
        .height(80);
      } else {
        List({ space: this.CELL_GAP }) {
          ForEach(
            this.generateHeatmapData(),
            (week: HeatmapDay[], _weekIndex: number) => {
              ListItem() {
                Column({ space: this.CELL_GAP }) {
                  ForEach(
                    week,
                    (day: HeatmapDay) => {
                      Column()
                        .width(this.CELL_WIDTH)
                        .height(this.CELL_HEIGHT)
                        .borderRadius(2)
                        .backgroundColor(this.getHeatColor(day.count));
                    },
                    (day: HeatmapDay) => day.date,
                  )
                }
              };
            },
            (_week: HeatmapDay[], weekIndex: number) => weekIndex.toString(),
          )
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .width("100%");
      }

      // 图例
      Row({ space: 8 }) {
        Text("少")
          .fontSize(10)
          .fontColor(this.app.theme.palette.textTertiary)
        Row({ space: 3 }) {
          Column()
            .width(this.CELL_WIDTH)
            .height(this.CELL_HEIGHT)
            .borderRadius(2)
            .backgroundColor(this.app.theme.palette.surfaceSecondary)
          Column()
            .width(this.CELL_WIDTH)
            .height(this.CELL_HEIGHT)
            .borderRadius(2)
            .backgroundColor(this.app.theme.palette.heatmapLow)
          Column()
            .width(this.CELL_WIDTH)
            .height(this.CELL_HEIGHT)
            .borderRadius(2)
            .backgroundColor(this.app.theme.palette.heatmapMedium)
          Column()
            .width(this.CELL_WIDTH)
            .height(this.CELL_HEIGHT)
            .borderRadius(2)
            .backgroundColor(this.app.theme.palette.heatmapHigh)
        }
        Text("多")
          .fontSize(10)
          .fontColor(this.app.theme.palette.textTertiary)
      }
    }
    .width("100%")
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
