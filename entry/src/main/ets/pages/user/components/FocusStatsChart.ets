import { AppState, useAppState } from '../../../app/AppStates';
import { FocusRepository } from '../../../core/repositories/FocusRepository';

interface FocusDayBar {
  dateKey: string;
  label: string;
  duration: number;
}

@ComponentV2
export struct FocusStatsChart {
  @Local private app: AppState = useAppState();
  @Local private bars: Array<FocusDayBar> = [];
  @Local private totalDuration: number = 0;
  @Local private totalCount: number = 0;
  @Local private loading: boolean = false;

  private repository: FocusRepository = new FocusRepository();
  private readonly DAY_COUNT: number = 7;
  private readonly WEEKDAY_LABELS: Array<string> = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void {
    this.loadStats();
  }

  private async loadStats(): Promise<void> {
    this.loading = true;
    try {
      const dailyDurationMap: Record<string, number> = await this.repository.getDailyDurationMap(this.DAY_COUNT);
      this.totalDuration = await this.repository.getTotalDuration();
      this.totalCount = await this.repository.getTotalCount();
      this.bars = this.buildBars(dailyDurationMap);
    } catch (_error) {
      this.bars = [];
      this.totalDuration = 0;
      this.totalCount = 0;
    } finally {
      this.loading = false;
    }
  }

  private buildBars(durationMap: Record<string, number>): Array<FocusDayBar> {
    const result: Array<FocusDayBar> = [];
    const weekStart: Date = this.resolveWeekStart(new Date());

    for (let index = 0; index < this.DAY_COUNT; index++) {
      const currentDate: Date = new Date(weekStart);
      currentDate.setDate(weekStart.getDate() + index);
      const dateKey: string = this.formatDateKey(currentDate);
      result.push({
        dateKey,
        label: this.WEEKDAY_LABELS[index],
        duration: durationMap[dateKey] ? durationMap[dateKey] : 0,
      });
    }

    return result;
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

  private resolveMaxDuration(): number {
    let maxDuration: number = 0;
    for (let index = 0; index < this.bars.length; index++) {
      maxDuration = Math.max(maxDuration, this.bars[index].duration);
    }
    return maxDuration;
  }

  private resolveBarHeight(duration: number): number {
    const maxDuration: number = this.resolveMaxDuration();
    if (duration <= 0 || maxDuration <= 0) {
      return 8;
    }
    return Math.max(16, Math.floor(duration / maxDuration * 112));
  }

  private formatDuration(seconds: number): string {
    if (seconds <= 0) {
      return '0 分钟';
    }
    if (seconds >= 3600) {
      return `${(seconds / 3600).toFixed(1)} 小时`;
    }
    const minutes: number = Math.max(1, Math.round(seconds / 60));
    return `${minutes} 分钟`;
  }

  private formatShortDuration(seconds: number): string {
    if (seconds <= 0) {
      return '0';
    }
    const minutes: number = Math.max(1, Math.round(seconds / 60));
    return `${minutes}分`;
  }

  private resolveSummary(): string {
    if (this.totalCount <= 0) {
      return '还没有专注记录';
    }
    return '本周 ' + this.formatDuration(this.resolveWeeklyDuration()) + ' | 累计 ' + this.totalCount + ' 次';
  }

  private resolveWeeklyDuration(): number {
    let weeklyDuration: number = 0;
    for (let index = 0; index < this.bars.length; index++) {
      weeklyDuration += this.bars[index].duration;
    }
    return weeklyDuration;
  }

  @Builder
  private buildBar(item: FocusDayBar) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height(120)
          .borderRadius(16)
          .backgroundColor(this.app.theme.palette.surfaceSecondary);

        Column()
          .width('100%')
          .height(this.resolveBarHeight(item.duration))
          .borderRadius(16)
          .backgroundColor(item.duration > 0 ? this.app.theme.palette.primary : this.app.theme.palette.border);
      }
      .width('100%')
      .height(120);

      Text(this.formatShortDuration(item.duration))
        .fontSize(10)
        .fontColor(this.app.theme.palette.textTertiary);

      Text(item.label)
        .fontSize(11)
        .fontColor(this.app.theme.palette.textSecondary);
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center);
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('本周专注时长')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textPrimary);

          Text(this.resolveSummary())
            .fontSize(12)
            .fontColor(this.app.theme.palette.textSecondary);
        }
        .alignItems(HorizontalAlign.Start);

        Blank();

        Text('周一至周日')
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
        .height(120);
      } else if (this.totalCount <= 0) {
        Column({ space: 8 }) {
          Text('还没有图表数据')
            .fontSize(14)
            .fontColor(this.app.theme.palette.textSecondary);
          Text('开始一次专注后，这里会按周一到周日展示本周的专注时长柱状图。')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(this.app.theme.palette.textTertiary)
            .textAlign(TextAlign.Center);
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.app.theme.palette.surfaceSecondary)
        .borderRadius(18);
      } else {
        Row({ space: 10 }) {
          ForEach(
            this.bars,
            (item: FocusDayBar) => {
              this.buildBar(item);
            },
            (item: FocusDayBar) => item.dateKey,
          );
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom);
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
