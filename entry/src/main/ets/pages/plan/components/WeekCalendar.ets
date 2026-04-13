import { AppState, useAppState } from "../../../app/AppStates";
import { PlanPageState, usePlanPageState } from "../PlanPageState";

/**
 * 周视图日历。
 * 提供周单位横向滑动吸附、日期选中和双击回今日能力。
 */
@ComponentV2
export struct WeekCalendar {
  @Local private app: AppState = useAppState();
  @Local private state: PlanPageState = usePlanPageState();
  @Local private lastTapAt: number = 0;
  @Local private lastTapEventAt: number = 0;
  @Local private swiperIndex: number = 2;
  @Local private ignoreNextSwiperChange: boolean = false;
  private readonly dayMs: number = 24 * 60 * 60 * 1000;
  private readonly centerSwiperIndex: number = 2;
  private readonly weekOffsets: Array<number> = [-2, -1, 0, 1, 2];

  private resolveWeekDays(weekOffset: number): Array<number> {
    const list: Array<number> = [];
    const weekStart = this.state.currentWeekBase + weekOffset * 7 * this.dayMs;
    for (let i = 0; i < 7; i++) {
      list.push(weekStart + i * this.dayMs);
    }
    return list;
  }

  private toDayStart(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  private isSelectedDay(dayTimestamp: number): boolean {
    return this.toDayStart(dayTimestamp) === this.toDayStart(this.state.selectedDate);
  }

  private resolveWeekdayLabel(dayTimestamp: number): string {
    const weekday = new Date(dayTimestamp).getDay();
    if (weekday === 0) {
      return "日";
    }
    if (weekday === 1) {
      return "一";
    }
    if (weekday === 2) {
      return "二";
    }
    if (weekday === 3) {
      return "三";
    }
    if (weekday === 4) {
      return "四";
    }
    if (weekday === 5) {
      return "五";
    }
    return "六";
  }

  private resolveCurrentMonthText(): string {
    const month = new Date(this.state.selectedDate).getMonth() + 1;
    return `${month}`;
  }

  private handleTapReturnToday(): boolean {
    const now = Date.now();
    // 去重同一次点击在父子节点触发的重复回调，避免误判为双击。
    if (now - this.lastTapEventAt < 80) {
      return false;
    }
    this.lastTapEventAt = now;
    if (now - this.lastTapAt <= 320) {
      this.lastTapAt = 0;
      this.state.jumpToToday();
      this.resetSwiperToCenter();
      return true;
    }
    this.lastTapAt = now;
    return false;
  }

  private resetSwiperToCenter(): void {
    if (this.swiperIndex === this.centerSwiperIndex) {
      return;
    }
    this.ignoreNextSwiperChange = true;
    this.swiperIndex = this.centerSwiperIndex;
  }

  private handleWeekChange(index: number): void {
    if (this.ignoreNextSwiperChange) {
      this.ignoreNextSwiperChange = false;
      return;
    }
    const deltaWeek = index - this.centerSwiperIndex;
    if (deltaWeek === 0) {
      return;
    }
    this.state.shiftWeek(deltaWeek);
    this.resetSwiperToCenter();
  }

  @Builder
  private buildWeekPage(weekOffset: number) {
    Row({ space: 4 }) {
      ForEach(
        this.resolveWeekDays(weekOffset),
        (dayTimestamp: number) => {
          this.buildDayItem(dayTimestamp);
        },
        (dayTimestamp: number) => `${weekOffset}_${dayTimestamp}_${this.state.selectedDate}`,
      )
    }
    .width("100%")
    .justifyContent(FlexAlign.SpaceBetween);
  }

  @Builder
  private buildDayItem(dayTimestamp: number) {
    Column({ space: 5 }) {
      Text(this.resolveWeekdayLabel(dayTimestamp))
        .fontSize(12)
        .fontColor(
          this.isSelectedDay(dayTimestamp)
            ? this.app.theme.palette.primary
            : this.app.theme.palette.textSecondary,
        )
      Text(`${new Date(dayTimestamp).getDate()}`)
        .fontSize(14)
        .fontWeight(this.isSelectedDay(dayTimestamp) ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(
          this.isSelectedDay(dayTimestamp)
            ? this.app.theme.palette.surface
            : this.app.theme.palette.textPrimary,
        )
        .width(30)
        .height(30)
        .textAlign(TextAlign.Center)
        .borderRadius(15)
        .backgroundColor(
          this.isSelectedDay(dayTimestamp) ? this.app.theme.palette.primary : "transparent",
        )
    }
    .width(40)
    .padding({ top: 4, bottom: 4 })
    .borderRadius(12)
    .onClick(() => {
      if (this.handleTapReturnToday()) {
        return;
      }
      this.state.selectDate(dayTimestamp);
    });
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 0 }) {
        Column({ space: 2 }) {
          Text(this.resolveCurrentMonthText())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textSecondary)
          Text("月")
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.app.theme.palette.textSecondary)
        }
        .width(20)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: -5 })
        Swiper() {
          ForEach(
            this.weekOffsets,
            (weekOffset: number) => {
              this.buildWeekPage(weekOffset);
            },
            (weekOffset: number) =>
              `${weekOffset}_${this.state.currentWeekBase}_${this.state.selectedDate}`,
          )
        }
        .layoutWeight(1)
        .height(60)
        .loop(false)
        .index(this.swiperIndex)
        .indicator(false)
        .onChange((index: number) => {
          this.swiperIndex = index;
          this.handleWeekChange(index);
        })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
      Text("提示：双击日历可快速回到今天")
        .fontSize(11)
        .fontColor(this.app.theme.palette.textTertiary)
    }
    .width("100%")
    .padding(14)
    .borderRadius(20)
    .backgroundColor(this.app.theme.palette.surface)
    .onClick(() => {
      this.handleTapReturnToday();
    });
  }
}
