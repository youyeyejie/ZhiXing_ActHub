import { Plan } from '../../core/models/Plan';
import { PlanRepository } from '../../core/repositories/PlanRepository';

@ObservedV2
export class PlanPageState {
  private readonly dayMs: number = 24 * 60 * 60 * 1000;
  private planRepository: PlanRepository = new PlanRepository();

  @Trace public selectedDate: number = 0;
  @Trace public currentWeekBase: number = 0;
  @Trace public plans: Array<Plan> = [];
  @Trace public visiblePlans: Array<Plan> = [];

  @Trace public isEditorVisible: boolean = false;
  @Trace public isDetailVisible: boolean = false;
  @Trace public editingPlanId: string = '';
  @Trace public creatingPlanId: string = '';

  @Trace public undoVisible: boolean = false;
  @Trace public undoMessage: string = '';

  private pendingDeletePlanId: string = '';
  private pendingDeletePlanSnapshot: Plan | null = null;
  private pendingDeleteTimerId: number = -1;
  private refreshTask: Promise<void> | null = null;

  constructor() {
    const today = this.toDayStart(Date.now());
    this.selectedDate = today;
    this.currentWeekBase = this.resolveWeekStart(today);
  }

  private safeTrim(value: string): string {
    const text = `${value}`.trim();
    if (text === 'undefined' || text === 'null') {
      return '';
    }
    return text;
  }

  private normalizeSwitchFlag(value: number): number {
    return value === 1 ? 1 : 0;
  }

  private toDayStart(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  private resolveWeekStart(dayStart: number): number {
    const date = new Date(dayStart);
    const weekday = date.getDay();
    const mondayOffset = weekday === 0 ? 6 : weekday - 1;
    return dayStart - mondayOffset * this.dayMs;
  }

  private sortPlansByStartTime(list: Array<Plan>): Array<Plan> {
    const sorted = list.slice();
    sorted.sort((a: Plan, b: Plan) => {
      if (a.startTime === b.startTime) {
        return b.updatedAt - a.updatedAt;
      }
      return a.startTime - b.startTime;
    });
    return sorted;
  }

  private copyPlan(source: Plan): Plan {
    const plan = new Plan();
    plan.id = source.id;
    plan.content = source.content;
    plan.timestamp = source.timestamp;
    plan.duration = source.duration;
    plan.startTime = source.startTime;
    plan.endTime = source.endTime;
    plan.location = source.location;
    plan.isCourse = source.isCourse;
    plan.description = source.description;
    plan.loopRule = source.loopRule;
    plan.createdAt = source.createdAt;
    plan.updatedAt = source.updatedAt;
    return plan;
  }

  async refreshAll(): Promise<void> {
    if (this.refreshTask !== null) {
      return this.refreshTask;
    }
    this.refreshTask = (async (): Promise<void> => {
      try {
        await this.refreshAllInternal();
      } finally {
        this.refreshTask = null;
      }
    })();
    return this.refreshTask;
  }

  private async refreshAllInternal(): Promise<void> {
    const list: Array<Plan> = await this.planRepository.findAll();
    this.plans = this.sortPlansByStartTime(list);
    this.syncVisiblePlans();
  }

  private syncVisiblePlans(): void {
    const dayStart = this.toDayStart(this.selectedDate);
    const dayEnd = dayStart + this.dayMs;
    const pendingDeleteId = this.safeTrim(this.pendingDeletePlanId);
    const filtered = this.plans.filter((item: Plan) => {
      const itemId = this.safeTrim(item.id);
      if (pendingDeleteId.length > 0 && itemId === pendingDeleteId) {
        return false;
      }
      const startTime = item.startTime;
      const endTime = item.endTime > startTime ? item.endTime : startTime;
      return startTime < dayEnd && endTime > dayStart;
    });
    this.visiblePlans = this.sortPlansByStartTime(filtered);
  }

  selectDate(timestamp: number): void {
    const dayStart = this.toDayStart(timestamp);
    this.selectedDate = dayStart;
    this.currentWeekBase = this.resolveWeekStart(dayStart);
    this.syncVisiblePlans();
  }

  shiftWeek(weekOffset: number): void {
    if (weekOffset === 0) {
      return;
    }
    this.selectDate(this.selectedDate + weekOffset * 7 * this.dayMs);
  }

  jumpToToday(): void {
    this.selectDate(Date.now());
  }

  openCreatePlan(): void {
    this.creatingPlanId = this.newId('plan');
    this.editingPlanId = '';
    this.isEditorVisible = true;
  }

  closePlanEditor(): void {
    this.isEditorVisible = false;
    this.creatingPlanId = '';
  }

  openPlanDetail(planId: string): void {
    const normalizedId = this.safeTrim(planId);
    if (normalizedId.length === 0) {
      return;
    }
    this.editingPlanId = normalizedId;
    this.isDetailVisible = true;
  }

  closePlanDetail(): void {
    this.isDetailVisible = false;
    this.editingPlanId = '';
  }

  private resolvePlanById(planId: string): Plan | null {
    const normalizedId = this.safeTrim(planId);
    if (normalizedId.length === 0) {
      return null;
    }
    const found = this.plans.find((item: Plan) => this.safeTrim(item.id) === normalizedId);
    return found ? found : null;
  }

  private fillComputedFields(plan: Plan): void {
    plan.isCourse = this.normalizeSwitchFlag(plan.isCourse);
    plan.duration = plan.endTime > plan.startTime ? plan.endTime - plan.startTime : 0;
    if (plan.timestamp <= 0) {
      plan.timestamp = plan.startTime > 0 ? plan.startTime : Date.now();
    }
  }

  private applyLocalPlanUpdate(updated: Plan): void {
    const updatedId = this.safeTrim(updated.id);
    const nextList: Array<Plan> = [];
    let replaced = false;
    for (let i = 0; i < this.plans.length; i++) {
      const currentId = this.safeTrim(this.plans[i].id);
      if (currentId === updatedId) {
        nextList.push(updated);
        replaced = true;
      } else {
        nextList.push(this.plans[i]);
      }
    }
    if (!replaced) {
      nextList.push(updated);
    }
    this.plans = this.sortPlansByStartTime(nextList);
    this.syncVisiblePlans();
  }

  async createPlan(
    content: string,
    startTime: number,
    endTime: number,
    location: string,
    isCourse: number,
    description: string
  ): Promise<boolean> {
    const title = this.safeTrim(content);
    if (title.length === 0) {
      return false;
    }
    if (startTime <= 0 || endTime <= 0 || endTime <= startTime) {
      return false;
    }

    const now = Date.now();
    const plan = new Plan();
    plan.id = this.creatingPlanId.length > 0 ? this.creatingPlanId : this.newId('plan');
    plan.content = title;
    plan.startTime = startTime;
    plan.endTime = endTime;
    plan.location = this.safeTrim(location);
    plan.isCourse = this.normalizeSwitchFlag(isCourse);
    plan.description = this.safeTrim(description);
    plan.loopRule = '';
    plan.timestamp = now;
    plan.createdAt = now;
    plan.updatedAt = now;
    this.fillComputedFields(plan);

    const ok = await this.planRepository.insert(plan);
    if (!ok) {
      return false;
    }
    await this.refreshAll();
    this.selectDate(startTime);
    return true;
  }

  private async updatePlan(
    planId: string,
    updater: (plan: Plan) => boolean
  ): Promise<boolean> {
    const normalizedId = this.safeTrim(planId);
    if (normalizedId.length === 0) {
      return false;
    }

    let target = this.resolvePlanById(normalizedId);
    if (target === null) {
      const fromRepo = await this.planRepository.findById(normalizedId);
      if (fromRepo === null) {
        return false;
      }
      target = fromRepo;
    }

    const working = this.copyPlan(target);
    const changed = updater(working);
    if (!changed) {
      return false;
    }
    working.updatedAt = Date.now();
    this.fillComputedFields(working);
    await this.planRepository.save(working);
    this.applyLocalPlanUpdate(working);
    return true;
  }

  async updatePlanContent(planId: string, content: string): Promise<void> {
    const nextTitle = this.safeTrim(content);
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (this.safeTrim(plan.content) === nextTitle) {
        return false;
      }
      plan.content = nextTitle;
      return true;
    });
  }

  async updatePlanTime(planId: string, startTime: number, endTime: number): Promise<boolean> {
    if (startTime <= 0 || endTime <= 0 || endTime <= startTime) {
      return false;
    }
    return this.updatePlan(planId, (plan: Plan): boolean => {
      if (plan.startTime === startTime && plan.endTime === endTime) {
        return false;
      }
      plan.startTime = startTime;
      plan.endTime = endTime;
      return true;
    });
  }

  async updatePlanLocation(planId: string, location: string): Promise<void> {
    const nextLocation = this.safeTrim(location);
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (this.safeTrim(plan.location) === nextLocation) {
        return false;
      }
      plan.location = nextLocation;
      return true;
    });
  }

  async updatePlanType(planId: string, isCourse: number): Promise<void> {
    const nextType = this.normalizeSwitchFlag(isCourse);
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (this.normalizeSwitchFlag(plan.isCourse) === nextType) {
        return false;
      }
      plan.isCourse = nextType;
      return true;
    });
  }

  async updatePlanDescription(planId: string, description: string): Promise<void> {
    const nextDescription = this.safeTrim(description);
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (this.safeTrim(plan.description) === nextDescription) {
        return false;
      }
      plan.description = nextDescription;
      return true;
    });
  }

  requestDeletePlan(planId: string): void {
    const normalizedId = this.safeTrim(planId);
    if (normalizedId.length === 0) {
      return;
    }
    const target = this.resolvePlanById(normalizedId);
    if (target === null) {
      return;
    }

    this.clearPendingDelete();
    this.pendingDeletePlanId = normalizedId;
    this.pendingDeletePlanSnapshot = this.copyPlan(target);
    this.undoMessage = '已删除日程';
    this.undoVisible = true;
    this.plans = this.sortPlansByStartTime(
      this.plans.filter((item: Plan) => this.safeTrim(item.id) !== normalizedId)
    );
    if (this.safeTrim(this.editingPlanId) === normalizedId) {
      this.closePlanDetail();
    }
    this.syncVisiblePlans();
    this.pendingDeleteTimerId = setTimeout(async (): Promise<void> => {
      await this.commitDeletePlan();
    }, 5000);
  }

  undoDelete(): void {
    const snapshot = this.pendingDeletePlanSnapshot;
    this.clearPendingDelete();
    this.undoVisible = false;
    if (snapshot !== null) {
      const snapshotId = this.safeTrim(snapshot.id);
      const exists = this.plans.some((item: Plan) => this.safeTrim(item.id) === snapshotId);
      if (!exists) {
        this.plans = this.sortPlansByStartTime([...this.plans, snapshot]);
      }
    }
    this.syncVisiblePlans();
  }

  async commitDeletePlan(): Promise<void> {
    const planId = this.safeTrim(this.pendingDeletePlanId);
    this.clearPendingDelete();
    this.undoVisible = false;
    if (planId.length === 0) {
      return;
    }
    await this.planRepository.removeById(planId);
    await this.refreshAll();
  }

  closeUndo(): void {
    this.undoVisible = false;
  }

  private clearPendingDelete(): void {
    this.pendingDeletePlanId = '';
    this.pendingDeletePlanSnapshot = null;
    if (this.pendingDeleteTimerId >= 0) {
      clearTimeout(this.pendingDeleteTimerId);
      this.pendingDeleteTimerId = -1;
    }
  }

  private newId(prefix: string): string {
    const millis = Date.now();
    const rand = Math.floor(Math.random() * 1_000_000);
    return `${prefix}_${millis}_${rand}`;
  }
}

const PLAN_PAGE_STATE: PlanPageState = new PlanPageState();

export function usePlanPageState(): PlanPageState {
  return PLAN_PAGE_STATE;
}
