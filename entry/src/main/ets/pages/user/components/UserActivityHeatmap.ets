import { AppState, useAppState } from '../../../app/AppStates';
import { IdeaRepository } from '../../../core/repositories/IdeaRepository';

interface UserHeatmapDay {
  dateKey: string;
  count: number;
}

@ComponentV2
export struct UserActivityHeatmap {
  @Local private app: AppState = useAppState();
  @Local private weeks: Array<Array<UserHeatmapDay>> = [];
  @Local private totalCount: number = 0;
  @Local private totalLength: number = 0;
  @Local private loading: boolean = false;

  private repository: IdeaRepository = new IdeaRepository();
  private readonly WEEK_COUNT: number = 6;
  private readonly CELL_GAP: number = 6;
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

    for (let weekIndex = 0; weekIndex < this.WEEK_COUNT; weekIndex++) {
      const row: Array<UserHeatmapDay> = [];
      for (let dayIndex = 0; dayIndex < this.WEEKDAY_LABELS.length; dayIndex++) {
        const currentDate: Date = new Date(gridStart);
        currentDate.setDate(gridStart.getDate() + weekIndex * 7 + dayIndex);
        const dateKey: string = this.formatDateKey(currentDate);
        row.push({
          dateKey,
          count: countMap[dateKey] ? countMap[dateKey] : 0,
        });
      }
      result.push(row);
    }

    return result;
  }

  private resolveGridStart(date: Date): Date {
    const startOfWeek: Date = this.resolveWeekStart(date);
    startOfWeek.setDate(startOfWeek.getDate() - (this.WEEK_COUNT - 1) * 7);
    return startOfWeek;
  }

  private resolveWeekStart(date: Date): Date {
    const result: Date = new Date(date);
    result.setHours(0, 0, 0, 0);
    const weekDay: number = result.getDay();
    const offset: number = weekDay === 0 ? 6 : weekDay - 1;
    result.setDate(result.getDate() - offset);
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

  private getHeatColor(count: number): string {
    if (count === 0) {
      return this.app.theme.palette.surfaceSecondary;
    }
    if (count <= 2) {
      return this.app.theme.isDark ? '#1E4A2D' : '#C6E5C8';
    }
    if (count <= 5) {
      return this.app.theme.isDark ? '#2E6B4A' : '#7BC99A';
    }
    return '#4CAF7A';
  }

  @Builder
  private buildHeatCell(day: UserHeatmapDay) {
    Column()
      .layoutWeight(1)
      .height(20)
      .borderRadius(6)
      .backgroundColor(this.getHeatColor(day.count));
  }

  @Builder
  private buildWeekRow(week: Array<UserHeatmapDay>, weekIndex: number) {
    Row({ space: this.CELL_GAP }) {
      ForEach(
        week,
        (day: UserHeatmapDay) => {
          this.buildHeatCell(day);
        },
        (day: UserHeatmapDay) => `${weekIndex}-${day.dateKey}`,
      );
    }
    .width('100%');
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

        Text(`近 ${this.WEEK_COUNT} 周`)
          .fontSize(12)
          .fontColor(this.app.theme.palette.textTertiary);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      Row({ space: this.CELL_GAP }) {
        ForEach(
          this.WEEKDAY_LABELS,
          (label: string) => {
            Text(label)
              .layoutWeight(1)
              .fontSize(11)
              .textAlign(TextAlign.Center)
              .fontColor(this.app.theme.palette.textTertiary);
          },
          (label: string) => label,
        );
      }
      .width('100%');

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
        .height(144);
      } else {
        Column({ space: this.CELL_GAP }) {
          ForEach(
            this.weeks,
            (week: Array<UserHeatmapDay>, weekIndex: number) => {
              this.buildWeekRow(week, weekIndex);
            },
            (_week: Array<UserHeatmapDay>, weekIndex: number) => weekIndex.toString(),
          );
        }
        .width('100%');
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
            .backgroundColor(this.app.theme.isDark ? '#1E4A2D' : '#C6E5C8');
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor(this.app.theme.isDark ? '#2E6B4A' : '#7BC99A');
          Column()
            .width(12)
            .height(12)
            .borderRadius(3)
            .backgroundColor('#4CAF7A');
        }
        Text('多')
          .fontSize(10)
          .fontColor(this.app.theme.palette.textTertiary);
      }

      if (!this.loading && this.totalCount <= 0) {
        Text('还没有闪记记录，开始记录后会在这里逐周点亮。')
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
