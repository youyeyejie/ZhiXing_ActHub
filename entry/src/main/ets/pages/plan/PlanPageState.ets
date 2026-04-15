import { Plan } from '../../core/models/Plan';
import { PlanRepository } from '../../core/repositories/PlanRepository';
import { UndoStackItem } from '../../components/feedback/UndoNotificationStack';

class PlanUndoTask {
  taskId: string;
  plan: Plan;
  originalIndex: number;
  timerId: number;
  deadlineMs: number;

  constructor(taskId: string, plan: Plan, originalIndex: number, timerId: number, deadlineMs: number) {
    this.taskId = taskId;
    this.plan = plan;
    this.originalIndex = originalIndex;
    this.timerId = timerId;
    this.deadlineMs = deadlineMs;
  }
}

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
  @Trace public editingPlanId: number = 0;
  @Trace public undoTasks: Array<PlanUndoTask> = [];
  private undoTaskSeq: number = 0;
  private refreshTask: Promise<void> | null = null;

  constructor() {
    const today = this.toDayStart(Date.now());
    this.selectedDate = today;
    this.currentWeekBase = this.resolveWeekStart(today);
  }

  private normalizeId(value: number): number {
    return value > 0 ? value : 0;
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
    const filtered = this.plans.filter((item: Plan) => {
      const itemId = this.normalizeId(item.id);
      if (this.hasUndoTaskForPlan(itemId)) {
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
    this.editingPlanId = 0;
    this.isEditorVisible = true;
  }

  closePlanEditor(): void {
    this.isEditorVisible = false;
  }

  openPlanDetail(planId: number): void {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return;
    }
    this.editingPlanId = normalizedId;
    this.isDetailVisible = true;
  }

  closePlanDetail(): void {
    this.isDetailVisible = false;
    this.editingPlanId = 0;
  }

  private resolvePlanById(planId: number): Plan | null {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return null;
    }
    const found = this.plans.find((item: Plan) => this.normalizeId(item.id) === normalizedId);
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
    const updatedId = this.normalizeId(updated.id);
    const nextList: Array<Plan> = [];
    let replaced = false;
    for (let i = 0; i < this.plans.length; i++) {
      const currentId = this.normalizeId(this.plans[i].id);
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
    const title = `${content}`.trim();
    if (title.length === 0) {
      return false;
    }
    if (startTime <= 0 || endTime <= 0 || endTime <= startTime) {
      return false;
    }

    const now = Date.now();
    const plan = new Plan();
    plan.content = title;
    plan.startTime = startTime;
    plan.endTime = endTime;
    plan.location = `${location}`.trim();
    plan.isCourse = this.normalizeSwitchFlag(isCourse);
    plan.description = `${description}`.trim();
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
    planId: number,
    updater: (plan: Plan) => boolean
  ): Promise<boolean> {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
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

  async updatePlanContent(planId: number, content: string): Promise<void> {
    const nextTitle = `${content}`.trim();
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (`${plan.content}`.trim() === nextTitle) {
        return false;
      }
      plan.content = nextTitle;
      return true;
    });
  }

  async updatePlanTime(planId: number, startTime: number, endTime: number): Promise<boolean> {
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

  async updatePlanLocation(planId: number, location: string): Promise<void> {
    const nextLocation = `${location}`.trim();
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (`${plan.location}`.trim() === nextLocation) {
        return false;
      }
      plan.location = nextLocation;
      return true;
    });
  }

  async updatePlanType(planId: number, isCourse: number): Promise<void> {
    const nextType = this.normalizeSwitchFlag(isCourse);
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (this.normalizeSwitchFlag(plan.isCourse) === nextType) {
        return false;
      }
      plan.isCourse = nextType;
      return true;
    });
  }

  async updatePlanDescription(planId: number, description: string): Promise<void> {
    const nextDescription = `${description}`.trim();
    await this.updatePlan(planId, (plan: Plan): boolean => {
      if (`${plan.description}`.trim() === nextDescription) {
        return false;
      }
      plan.description = nextDescription;
      return true;
    });
  }

  requestDeletePlan(planId: number): void {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return;
    }
    const target = this.resolvePlanById(normalizedId);
    if (target === null) {
      return;
    }
    if (this.hasUndoTaskForPlan(normalizedId)) {
      return;
    }

    const originalIndex = this.findPlanIndexById(normalizedId);
    const snapshot = this.copyPlan(target);
    const taskId = `plan_delete_${this.undoTaskSeq}`;
    this.undoTaskSeq = this.undoTaskSeq + 1;
    const deadlineMs = Date.now() + 5000;
    const timerId = setTimeout(async (): Promise<void> => {
      await this.commitDeletePlan(taskId);
    }, 5000);
    this.undoTasks = [...this.undoTasks, new PlanUndoTask(taskId, snapshot, originalIndex, timerId, deadlineMs)];
    this.plans = this.sortPlansByStartTime(this.plans.filter((item: Plan) => this.normalizeId(item.id) !== normalizedId));
    if (this.normalizeId(this.editingPlanId) === normalizedId) {
      this.closePlanDetail();
    }
    this.syncVisiblePlans();
  }

  undoDelete(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    this.closeUndo(taskId);
    const snapshotId = this.normalizeId(task.plan.id);
    const exists = this.plans.some((item: Plan) => this.normalizeId(item.id) === snapshotId);
    if (!exists) {
      const insertIndex = Math.max(0, Math.min(task.originalIndex, this.plans.length));
      const before = this.plans.slice(0, insertIndex);
      const after = this.plans.slice(insertIndex);
      this.plans = this.sortPlansByStartTime([...before, task.plan, ...after]);
      if (!this.isCurrentSelectedDateCovered(task.plan)) {
        this.syncVisiblePlans();
        return;
      }
    }
    this.syncVisiblePlans();
  }

  async commitDeletePlan(taskId: string): Promise<void> {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    const planId = this.normalizeId(task.plan.id);
    this.closeUndo(taskId);
    if (planId <= 0) {
      return;
    }
    await this.planRepository.removeById(planId);
    await this.refreshAll();
  }

  closeUndo(taskId: string): void {
    const task = this.findUndoTask(taskId);
    if (task === null) {
      return;
    }
    if (task.timerId >= 0) {
      clearTimeout(task.timerId);
    }
    this.undoTasks = this.undoTasks.filter((item: PlanUndoTask) => item.taskId !== taskId);
  }

  buildUndoStackItems(): Array<UndoStackItem> {
    const list: Array<UndoStackItem> = [];
    for (let i = 0; i < this.undoTasks.length; i++) {
      const task = this.undoTasks[i];
      const title = `${task.plan.content}`.trim();
      list.push(
        new UndoStackItem(
          task.taskId,
          `${title.length > 0 ? title : '日程'} 已删除`,
          '撤销',
          5000,
          task.deadlineMs,
        )
      );
    }
    return list;
  }

  private findUndoTask(taskId: string): PlanUndoTask | null {
    for (let i = 0; i < this.undoTasks.length; i++) {
      if (this.undoTasks[i].taskId === taskId) {
        return this.undoTasks[i];
      }
    }
    return null;
  }

  private hasUndoTaskForPlan(planId: number): boolean {
    const normalizedId = this.normalizeId(planId);
    return this.undoTasks.some((task: PlanUndoTask) => this.normalizeId(task.plan.id) === normalizedId);
  }

  private findPlanIndexById(planId: number): number {
    for (let i = 0; i < this.plans.length; i++) {
      if (this.normalizeId(this.plans[i].id) === planId) {
        return i;
      }
    }
    return this.plans.length;
  }

  private isCurrentSelectedDateCovered(plan: Plan): boolean {
    const dayStart = this.toDayStart(this.selectedDate);
    const dayEnd = dayStart + this.dayMs;
    const startTime = plan.startTime;
    const endTime = plan.endTime > startTime ? plan.endTime : startTime;
    return startTime < dayEnd && endTime > dayStart;
  }

}

const PLAN_PAGE_STATE: PlanPageState = new PlanPageState();

export function usePlanPageState(): PlanPageState {
  return PLAN_PAGE_STATE;
}
