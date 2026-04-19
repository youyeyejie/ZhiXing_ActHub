import { AppState, useAppState } from '../../../app/AppStates';
import { FocusRepository } from '../../../core/repositories/FocusRepository';

interface FocusDayBar {
  dateKey: string;
  label: string;
  duration: number;
}

interface FocusBarPage {
  anchorDateKey: string;
  rangeLabel: string;
  bars: Array<FocusDayBar>;
}

@ComponentV2
export struct FocusStatsChart {
  @Local private app: AppState = useAppState();
  @Local private pages: Array<FocusBarPage> = [];
  @Local private currentPageIndex: number = 0;
  @Local private totalDuration: number = 0;
  @Local private totalCount: number = 0;
  @Local private loading: boolean = false;

  private repository: FocusRepository = new FocusRepository();
  private readonly DAY_COUNT: number = 7;
  private readonly MAX_PAGE_COUNT: number = 12;
  private readonly WEEKDAY_LABELS: Array<string> = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void {
    this.loadStats();
  }

  @Monitor('app.focusStatsRefreshVersion')
  onFocusStatsRefreshVersionChanged(): void {
    this.loadStats();
  }

  private async loadStats(): Promise<void> {
    this.loading = true;
    try {
      const dailyDurationMap: Record<string, number> = await this.repository.getDailyDurationMap(this.DAY_COUNT * this.MAX_PAGE_COUNT);
      this.totalDuration = await this.repository.getTotalDuration();
      this.totalCount = await this.repository.getTotalCount();
      this.pages = this.buildPages(dailyDurationMap);
      this.currentPageIndex = this.pages.length > 0 ? this.pages.length - 1 : 0;
    } catch (_error) {
      this.pages = [];
      this.currentPageIndex = 0;
      this.totalDuration = 0;
      this.totalCount = 0;
    } finally {
      this.loading = false;
    }
  }

  private buildPages(durationMap: Record<string, number>): Array<FocusBarPage> {
    const result: Array<FocusBarPage> = [];
    const today: Date = this.resolveDayStart(new Date());

    for (let pageIndex = this.MAX_PAGE_COUNT - 1; pageIndex >= 0; pageIndex--) {
      const anchorDate: Date = new Date(today);
      anchorDate.setDate(today.getDate() - pageIndex * this.DAY_COUNT);
      result.push({
        anchorDateKey: this.formatDateKey(anchorDate),
        rangeLabel: this.buildRangeLabel(anchorDate),
        bars: this.buildBarsForAnchor(durationMap, anchorDate),
      });
    }

    return result;
  }

  private buildBarsForAnchor(durationMap: Record<string, number>, anchorDate: Date): Array<FocusDayBar> {
    const result: Array<FocusDayBar> = [];
    const startDate: Date = new Date(anchorDate);
    startDate.setDate(anchorDate.getDate() - this.DAY_COUNT + 1);

    for (let index = 0; index < this.DAY_COUNT; index++) {
      const currentDate: Date = new Date(startDate);
      currentDate.setDate(startDate.getDate() + index);
      const dateKey: string = this.formatDateKey(currentDate);
      const weekdayIndex: number = this.resolveWeekdayIndex(currentDate);
      result.push({
        dateKey,
        label: this.WEEKDAY_LABELS[weekdayIndex],
        duration: durationMap[dateKey] ? durationMap[dateKey] : 0,
      });
    }

    return result;
  }

  private resolveDayStart(date: Date): Date {
    const result: Date = new Date(date);
    result.setHours(0, 0, 0, 0);
    return result;
  }

  private resolveWeekdayIndex(date: Date): number {
    const weekDay: number = date.getDay();
    return weekDay === 0 ? 6 : weekDay - 1;
  }

  private formatDateKey(date: Date): string {
    const month: string = String(date.getMonth() + 1).padStart(2, '0');
    const day: string = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private buildRangeLabel(anchorDate: Date): string {
    const startDate: Date = new Date(anchorDate);
    startDate.setDate(anchorDate.getDate() - this.DAY_COUNT + 1);
    return `${startDate.getMonth() + 1}.${startDate.getDate()} - ${anchorDate.getMonth() + 1}.${anchorDate.getDate()}`;
  }

  private resolveMaxDuration(bars: Array<FocusDayBar>): number {
    let maxDuration: number = 0;
    for (let index = 0; index < bars.length; index++) {
      maxDuration = Math.max(maxDuration, bars[index].duration);
    }
    return maxDuration;
  }

  private resolveBarHeight(duration: number, bars: Array<FocusDayBar>): number {
    const maxDuration: number = this.resolveMaxDuration(bars);
    if (duration <= 0 || maxDuration <= 0) {
      return 12;
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
    return '近 7 天 ' + this.formatDuration(this.resolveCurrentPageDuration()) + ' | 累计 ' + this.totalCount + ' 次';
  }

  private resolveCurrentPageDuration(): number {
    if (this.pages.length <= 0 || this.currentPageIndex < 0 || this.currentPageIndex >= this.pages.length) {
      return 0;
    }

    let weeklyDuration: number = 0;
    const bars: Array<FocusDayBar> = this.pages[this.currentPageIndex].bars;
    for (let index = 0; index < bars.length; index++) {
      weeklyDuration += bars[index].duration;
    }
    return weeklyDuration;
  }

  @Builder
  private buildBar(item: FocusDayBar, bars: Array<FocusDayBar>) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height(120)
          .borderRadius(6)
          .backgroundColor(this.app.theme.palette.surfaceSecondary);

        Column()
          .width('100%')
          .height(this.resolveBarHeight(item.duration, bars))
          .borderRadius(6)
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

  @Builder
  private buildChartPage(page: FocusBarPage) {
    Row({ space: 10 }) {
      ForEach(
        page.bars,
        (item: FocusDayBar) => {
          this.buildBar(item, page.bars);
        },
        (item: FocusDayBar) => item.dateKey,
      );
    }
    .width('100%')
    .padding({ left: 6, right: 6 })
    .alignItems(VerticalAlign.Bottom);
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

        Text(this.pages.length > 0 ? this.pages[this.currentPageIndex].rangeLabel : '今天及前 6 天')
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
      } else {
        Swiper() {
          ForEach(
            this.pages,
            (page: FocusBarPage) => {
              this.buildChartPage(page);
            },
            (page: FocusBarPage) => page.anchorDateKey,
          )
        }
        .width('100%')
        .height(160)
        .loop(false)
        .index(this.currentPageIndex)
        .indicator(false)
        .onChange((index: number) => {
          this.currentPageIndex = index;
        });
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface);
  }
}
