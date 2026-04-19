import { AppState, useAppState } from '../../../app/AppStates';
import { IdeaRepository } from '../../../core/repositories/IdeaRepository';

/**
 * 组件功能简介：
 * - 用户活跃热力图单元数据结构，描述某天的活跃计数与未来态。
 *
 * 可传入项：
 * - `dateKey`、`count`、`isFuture`。
 *
 * 返回行为：
 * - 作为热力图网格渲染的数据单元。
 *
 * 副作用：
 * - 无。
 */
interface UserHeatmapDay {
  dateKey: string;
  count: number;
  isFuture: boolean;
}

/**
 * 组件功能简介：
 * - 用户活跃热力图组件，展示近多周闪记活跃分布与累计统计。
 *
 * 可传入项：
 * - 无（通过仓储加载统计并读取主题色）。
 *
 * 返回行为：
 * - 渲染热力网格及总条数/总字数指标。
 *
 * 副作用：
 * - 页面出现时会触发统计查询。
 */
@ComponentV2
export struct UserActivityHeatmap {
  @Local private app: AppState = useAppState();
  @Local private weeks: Array<Array<UserHeatmapDay>> = [];
  @Local private totalCount: number = 0;
  @Local private totalLength: number = 0;
  @Local private loading: boolean = false;

  private repository: IdeaRepository = new IdeaRepository();
  private readonly WEEK_COUNT: number = 14;
  private readonly CELL_GAP: number = 4;
  private readonly CELL_SIZE: number = 16;
  private readonly WEEKDAY_LABELS: Array<string> = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void {
    this.loadStats();
  }

  private async loadStats(): Promise<void> {
    this.loading = true;
    try {
      const countMap: Record<string, number> = await this.repository.getDailyCountMap(this.WEEK_COUNT * 7);
      this.totalCount = await this.repository.getTotalCount();
      this.totalLength = await this.repository.getTotalLength();
      this.weeks = this.buildWeeks(countMap);
    } catch (_error) {
      this.weeks = [];
      this.totalCount = 0;
      this.totalLength = 0;
    } finally {
      this.loading = false;
    }
  }

  private buildWeeks(countMap: Record<string, number>): Array<Array<UserHeatmapDay>> {
    const result: Array<Array<UserHeatmapDay>> = [];
    const gridStart: Date = this.resolveGridStart(new Date());
    const today: Date = this.resolveDayStart(new Date());

    for (let weekIndex = 0; weekIndex < this.WEEK_COUNT; weekIndex++) {
      const column: Array<UserHeatmapDay> = [];
      for (let dayIndex = 0; dayIndex < this.WEEKDAY_LABELS.length; dayIndex++) {
        const currentDate: Date = new Date(gridStart);
        currentDate.setDate(gridStart.getDate() + weekIndex * 7 + dayIndex);
        const dateKey: string = this.formatDateKey(currentDate);
        column.push({
          dateKey,
          count: countMap[dateKey] ? countMap[dateKey] : 0,
          isFuture: currentDate.getTime() > today.getTime(),
        });
      }
      result.push(column);
    }

    return result;
  }

  private resolveGridStart(date: Date): Date {
    const startOfWeek: Date = this.resolveWeekStart(date);
    startOfWeek.setDate(startOfWeek.getDate() - (this.WEEK_COUNT - 1) * 7);
    return startOfWeek;
  }

  private resolveWeekStart(date: Date): Date {
    const result: Date = this.resolveDayStart(date);
    const weekDay: number = result.getDay();
    const offset: number = weekDay === 0 ? 6 : weekDay - 1;
    result.setDate(result.getDate() - offset);
    return result;
  }

  private resolveDayStart(date: Date): Date {
    const result: Date = new Date(date);
    result.setHours(0, 0, 0, 0);
    return result;
  }

  private formatDateKey(date: Date): string {
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private formatNumber(num: number): string {
    if (num >= 10000) {
      return (num / 10000).toFixed(1) + ' 万';
    }
    return num.toString();
  }

  private formatMonthDay(date: Date): string {
    return `${date.getMonth() + 1}.${date.getDate()}`;
  }

  private resolveRangeText(): string {
    const startDate: Date = this.resolveGridStart(new Date());
    const endDate: Date = new Date(startDate);
    endDate.setDate(startDate.getDate() + this.WEEK_COUNT * 7 - 1);
    return `${this.formatMonthDay(startDate)} - ${this.formatMonthDay(endDate)}`;
  }

  private resolveMaxCount(): number {
    let maxCount: number = 0;
    for (let weekIndex = 0; weekIndex < this.weeks.length; weekIndex++) {
      const week: Array<UserHeatmapDay> = this.weeks[weekIndex];
      for (let dayIndex = 0; dayIndex < week.length; dayIndex++) {
        if (!week[dayIndex].isFuture) {
          maxCount = Math.max(maxCount, week[dayIndex].count);
        }
      }
    }
    return maxCount;
  }

  private getHeatColor(count: number): string {
    if (count === 0) {
      return this.app.theme.palette.surfaceSecondary;
    }

    const maxCount: number = this.resolveMaxCount();
    if (maxCount <= 0) {
      return this.app.theme.palette.heatmapLevel_1;
    }

    const ratio: number = count / maxCount;
    if (ratio <= 0.2) {
      return this.app.theme.palette.heatmapLevel_1;
    }
    if (ratio <= 0.4) {
      return this.app.theme.palette.heatmapLevel_2;
    }
    if (ratio <= 0.6) {
      return this.app.theme.palette.heatmapLevel_3;
    }
    if (ratio <= 0.8) {
      return this.app.theme.palette.heatmapLevel_4;
    }
    return this.app.theme.palette.heatmapLevel_5;
  }

  @Builder
  private buildHeatCell(day: UserHeatmapDay) {
    Column()
      .width(this.CELL_SIZE)
      .height(this.CELL_SIZE)
      .borderRadius(4)
      .backgroundColor(day.isFuture ? Color.Transparent : this.getHeatColor(day.count));
  }

  @Builder
  private buildWeekColumn(week: Array<UserHeatmapDay>, weekIndex: number) {
    Column({ space: this.CELL_GAP }) {
      ForEach(
        week,
        (day: UserHeatmapDay) => {
          this.buildHeatCell(day);
        },
        (day: UserHeatmapDay) => `${weekIndex}-${day.dateKey}`,
      );
    }
    .width(this.CELL_SIZE);
  }

  @Builder
  private buildWeekdayLabels() {
    Column({ space: this.CELL_GAP }) {
      ForEach(
        this.WEEKDAY_LABELS,
        (label: string) => {
          Row() {
            Text(label)
              .fontSize(11)
              .fontColor(this.app.theme.palette.textTertiary);
          }
          .width(16)
          .height(this.CELL_SIZE)
          .justifyContent(FlexAlign.Center);
        },
        (label: string) => label,
      );
    }
    .width(16);
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('活跃度')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary);

          Text(`${this.totalCount} 条笔记 · ${this.formatNumber(this.totalLength)} 字`)
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary);
        }
        .alignItems(HorizontalAlign.Start);

        Blank();

        Text(this.resolveRangeText())
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      if (this.loading) {
        Row() {
          Blank();
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.app.theme.palette.primary);
          Blank();
        }
        .width('100%')
        .height(140);
      } else {
        Row({ space: this.CELL_GAP }) {
          this.buildWeekdayLabels();

          Row({ space: this.CELL_GAP }) {
            ForEach(
              this.weeks,
              (week: Array<UserHeatmapDay>, weekIndex: number) => {
                this.buildWeekColumn(week, weekIndex);
              },
              (_week: Array<UserHeatmapDay>, weekIndex: number) => weekIndex.toString(),
            );
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('100%')
        .alignItems(VerticalAlign.Top);
      }

      Row({ space: 8 }) {
        Text('少')
          .fontSize(10)
          .fontColor(this.app.theme.palette.textTertiary);
        Row({ space: 3 }) {
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.palette.surfaceSecondary);
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.palette.heatmapLevel_1);
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.palette.heatmapLevel_2);
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.palette.heatmapLevel_3);
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.palette.heatmapLevel_4);
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.palette.heatmapLevel_5);
        }
        Text('多')
          .fontSize(10)
          .fontColor(this.app.theme.palette.textTertiary);
      }

      if (!this.loading && this.totalCount <= 0) {
        Text('还没有闪记记录，开始记录后会在这里按周点亮。')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(this.app.theme.palette.textTertiary);
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
