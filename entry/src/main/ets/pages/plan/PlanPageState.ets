import { Plan } from "../../core/models/Plan";
import { PlanRepository } from "../../core/repositories/PlanRepository";
import { CalendarReminderService } from "../../core/services/CalendarReminderService";
import { UndoStackItem } from "../../components/feedback/UndoNotificationStack";

/**
 * 组件功能简介：
 * - 日程页面撤销任务对象，保存删除回滚所需的日程快照与时间窗口。
 *
 * 可传入项：
 * - 构造参数包含任务 ID、日程快照、原始索引、计时器 ID 与截止时间。
 *
 * 返回行为：
 * - 创建撤销任务实例供状态层维护。
 *
 * 副作用：
 * - 无。
 */
class PlanUndoTask {
  taskId: string;
  plan: Plan;
  originalIndex: number;
  timerId: number;
  deadlineMs: number;

  constructor(
    taskId: string,
    plan: Plan,
    originalIndex: number,
    timerId: number,
    deadlineMs: number,
  ) {
    this.taskId = taskId;
    this.plan = plan;
    this.originalIndex = originalIndex;
    this.timerId = timerId;
    this.deadlineMs = deadlineMs;
  }
}

/**
 * 组件功能简介：
 * - 日程卡片视图模型，承载列表渲染所需追踪字段。
 *
 * 可传入项：
 * - `applyFrom(plan)` 传入日程实体。
 *
 * 返回行为：
 * - 同步并输出用于渲染的日程字段。
 *
 * 副作用：
 * - 更新追踪字段后会触发对应 UI 刷新。
 */
@ObservedV2
export class PlanItem {
  @Trace id: number = 0;
  @Trace content: string = "";
  @Trace startTime: number = 0;
  @Trace endTime: number = 0;
  @Trace location: string = "";
  @Trace isCourse: number = 0;
  @Trace enableRemind: number = 0;
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;

  applyFrom(plan: Plan): void {
    this.id = plan.id;
    this.content = plan.content;
    this.startTime = plan.startTime;
    this.endTime = plan.endTime;
    this.location = plan.location;
    this.isCourse = plan.isCourse;
    this.enableRemind = plan.enableRemind;
    this.createdAt = plan.createdAt;
    this.updatedAt = plan.updatedAt;
  }
}

/**
 * 组件功能简介：
 * - 日程页面状态容器，管理日期范围、日程列表、编辑态与撤销逻辑。
 *
 * 可传入项：
 * - 通过公开方法接收日程新增、编辑、删除及日期切换参数。
 *
 * 返回行为：
 * - 输出页面渲染所需的可见日程、卡片模型和交互状态。
 *
 * 副作用：
 * - 会读写日程仓储并根据设置触发提醒服务。
 */
@ObservedV2
export class PlanPageState {
  private readonly dayMs: number = 24 * 60 * 60 * 1000;
  private planRepository: PlanRepository = new PlanRepository();
  private calendarReminderService: CalendarReminderService = new CalendarReminderService();

  @Trace public selectedDate: number = 0;
  @Trace public currentWeekBase: number = 0;
  @Trace public plans: Array<Plan> = [];
  @Trace public visiblePlans: Array<Plan> = [];
  @Trace public visiblePlanCards: Array<PlanItem> = [];

  @Trace public isEditorVisible: boolean = false;
  @Trace public isDetailVisible: boolean = false;
  @Trace public editingPlanId: number = 0;
  @Trace public creatingPlanId: number = 0;
  @Trace public returnTodayRequestVersion: number = 0;
  @Trace public undoTasks: Array<PlanUndoTask> = [];
  @Trace public pendingRestoreMovePlanIds: Array<number> = [];
  private undoTaskSeq: number = 0;
  private refreshTask: Promise<void> | null = null;
  private planItemMap: Map<number, PlanItem> = new Map<number, PlanItem>();

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
      if (a.startTime !== b.startTime) {
        return a.startTime - b.startTime;
      }

      if (a.endTime !== b.endTime) {
        return a.endTime - b.endTime;
      }

      if (a.createdAt !== b.createdAt) {
        return a.createdAt - b.createdAt;
      }

      const idA = this.normalizeId(a.id);
      const idB = this.normalizeId(b.id);
      if (idA !== idB) {
        return idA - idB;
      }

      return 0;
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
    plan.reminderId = source.reminderId;
    plan.enableRemind = source.enableRemind;
    plan.version = source.version;
    plan.notifyVersion = source.notifyVersion;
    plan.createdAt = source.createdAt;
    plan.updatedAt = source.updatedAt;
    return plan;
  }

  private syncVisiblePlanCards(): void {
    const nextItemMap: Map<number, PlanItem> = new Map<number, PlanItem>();
    for (let i = 0; i < this.plans.length; i++) {
      const plan = this.plans[i];
      const planId = this.normalizeId(plan.id);
      if (planId <= 0) {
        continue;
      }
      let item = this.planItemMap.get(planId);
      if (item === undefined) {
        item = new PlanItem();
      }
      item.applyFrom(plan);
      nextItemMap.set(planId, item);
    }
    this.planItemMap = nextItemMap;

    const nextVisibleCards: Array<PlanItem> = [];
    for (let i = 0; i < this.visiblePlans.length; i++) {
      const planId = this.normalizeId(this.visiblePlans[i].id);
      if (planId <= 0) {
        continue;
      }
      const item = this.planItemMap.get(planId);
      if (item !== undefined) {
        nextVisibleCards.push(item);
      }
    }
    this.visiblePlanCards = nextVisibleCards;
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

  private sortVisiblePlanList(list: Array<Plan>): Array<Plan> {
    const sorted = this.sortPlansByStartTime(list);
    if (this.pendingRestoreMovePlanIds.length === 0) {
      return sorted;
    }

    const pendingSet: Set<number> = new Set<number>(
      this.pendingRestoreMovePlanIds.map((id: number) => this.normalizeId(id)),
    );
    const normal: Array<Plan> = [];
    const pending: Array<Plan> = [];
    for (let i = 0; i < sorted.length; i++) {
      const planId = this.normalizeId(sorted[i].id);
      if (planId > 0 && pendingSet.has(planId)) {
        pending.push(sorted[i]);
      } else {
        normal.push(sorted[i]);
      }
    }
    return [...normal, ...pending];
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
    this.visiblePlans = this.sortVisiblePlanList(filtered);
    this.syncVisiblePlanCards();
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

  shiftWeekBase(weekOffset: number): void {
    if (weekOffset === 0) {
      return;
    }
    const nextWeekBase = this.currentWeekBase + weekOffset * 7 * this.dayMs;
    this.currentWeekBase = this.resolveWeekStart(nextWeekBase);
  }

  jumpToToday(): void {
    this.selectDate(Date.now());
  }

  isSelectedDateToday(): boolean {
    return this.toDayStart(this.selectedDate) === this.toDayStart(Date.now());
  }

  requestReturnToTodayAnimated(): void {
    if (this.isSelectedDateToday()) {
      return;
    }
    this.returnTodayRequestVersion = this.returnTodayRequestVersion + 1;
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
    plan.enableRemind = this.normalizeSwitchFlag(plan.enableRemind);
    if (plan.reminderId < 0) {
      plan.reminderId = 0;
    }
    if (plan.notifyVersion < 0) {
      plan.notifyVersion = 0;
    }
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

  private resolvePersistedCreatedPlan(snapshot: Plan): Plan | null {
    for (let index = 0; index < this.plans.length; index++) {
      const current = this.plans[index];
      if (current.createdAt !== snapshot.createdAt) {
        continue;
      }
      if (current.updatedAt !== snapshot.updatedAt) {
        continue;
      }
      if (current.startTime !== snapshot.startTime || current.endTime !== snapshot.endTime) {
        continue;
      }
      if (current.content !== snapshot.content) {
        continue;
      }
      return this.copyPlan(current);
    }
    return null;
  }

  private shouldBumpReminderVersion(previousPlan: Plan, nextPlan: Plan): boolean {
    return previousPlan.content !== nextPlan.content
      || previousPlan.startTime !== nextPlan.startTime
      || previousPlan.endTime !== nextPlan.endTime
      || previousPlan.description !== nextPlan.description
      || this.normalizeSwitchFlag(previousPlan.enableRemind) !== this.normalizeSwitchFlag(nextPlan.enableRemind);
  }

  async createPlan(
    content: string,
    startTime: number,
    endTime: number,
    location: string,
    isCourse: number,
    description: string,
    remindEnabled: boolean,
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
    plan.loopRule = "";
    plan.reminderId = 0;
    plan.enableRemind = remindEnabled ? 1 : 0;
    plan.version = 1;
    plan.notifyVersion = 0;
    plan.timestamp = now;
    plan.createdAt = now;
    plan.updatedAt = now;
    this.fillComputedFields(plan);

    const ok = await this.planRepository.insert(plan);
    if (!ok) {
      return false;
    }
    await this.refreshAll();
    const persistedPlan = this.resolvePersistedCreatedPlan(plan);
    if (persistedPlan === null) {
      this.selectDate(startTime);
      return true;
    }
    const reminderChanged = await this.calendarReminderService.syncPlanReminderRecord(persistedPlan);
    if (reminderChanged) {
      await this.planRepository.save(persistedPlan);
      this.applyLocalPlanUpdate(persistedPlan);
    }
    this.selectDate(startTime);
    return true;
  }

  private async updatePlan(planId: number, updater: (plan: Plan) => boolean): Promise<boolean> {
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
    if (this.shouldBumpReminderVersion(target, working)) {
      working.version = target.version > 0 ? target.version + 1 : 1;
    } else {
      working.version = target.version > 0 ? target.version : 0;
    }
    this.fillComputedFields(working);
    await this.planRepository.save(working);
    const reminderChanged = await this.calendarReminderService.syncPlanReminderRecord(working);
    if (reminderChanged) {
      await this.planRepository.save(working);
    }
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

  async updatePlanReminderEnabled(planId: number, enabled: boolean): Promise<boolean> {
    const nextValue = enabled ? 1 : 0;
    return this.updatePlan(planId, (plan: Plan): boolean => {
      if (this.normalizeSwitchFlag(plan.enableRemind) === nextValue) {
        return false;
      }
      plan.enableRemind = nextValue;
      return true;
    });
  }

  requestDeletePlan(planId: number): void {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return;
    }
    this.clearPendingRestoreMove(normalizedId);
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
    this.undoTasks = [
      ...this.undoTasks,
      new PlanUndoTask(taskId, snapshot, originalIndex, timerId, deadlineMs),
    ];
    this.plans = this.sortPlansByStartTime(
      this.plans.filter((item: Plan) => this.normalizeId(item.id) !== normalizedId),
    );
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
      if (this.isCurrentSelectedDateCovered(task.plan)) {
        this.markPlanPendingRestoreMove(snapshotId);
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
    const deletingPlan = task.plan;
    const reminderChanged = await this.calendarReminderService.clearPlanReminderRecord(deletingPlan);
    if (reminderChanged) {
      await this.planRepository.save(deletingPlan);
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
          `${title.length > 0 ? title : "日程"} 已删除`,
          "撤销",
          5000,
          task.deadlineMs,
        ),
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
    return this.undoTasks.some(
      (task: PlanUndoTask) => this.normalizeId(task.plan.id) === normalizedId,
    );
  }

  isPlanPendingRestoreMove(planId: number): boolean {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return false;
    }
    return this.pendingRestoreMovePlanIds.some((id: number) => this.normalizeId(id) === normalizedId);
  }

  settlePendingRestoreMove(planId: number): void {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return;
    }
    if (!this.isPlanPendingRestoreMove(normalizedId)) {
      return;
    }
    animateTo({ duration: 280, curve: Curve.EaseInOut, playMode: PlayMode.Normal }, () => {
      this.clearPendingRestoreMove(normalizedId);
      this.syncVisiblePlans();
    });
  }

  private markPlanPendingRestoreMove(planId: number): void {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return;
    }

    const exists = this.pendingRestoreMovePlanIds.some(
      (id: number) => this.normalizeId(id) === normalizedId,
    );
    if (!exists) {
      this.pendingRestoreMovePlanIds = [...this.pendingRestoreMovePlanIds, normalizedId];
    }
  }

  private clearPendingRestoreMove(planId: number): void {
    const normalizedId = this.normalizeId(planId);
    if (normalizedId <= 0) {
      return;
    }

    const next = this.pendingRestoreMovePlanIds.filter(
      (id: number) => this.normalizeId(id) !== normalizedId,
    );
    if (next.length !== this.pendingRestoreMovePlanIds.length) {
      this.pendingRestoreMovePlanIds = next;
    }
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

  resetForReload(): void {
    for (let index = 0; index < this.undoTasks.length; index++) {
      if (this.undoTasks[index].timerId >= 0) {
        clearTimeout(this.undoTasks[index].timerId);
      }
    }
    const today = this.toDayStart(Date.now());
    this.selectedDate = today;
    this.currentWeekBase = this.resolveWeekStart(today);
    this.plans = [];
    this.visiblePlans = [];
    this.visiblePlanCards = [];
    this.isEditorVisible = false;
    this.isDetailVisible = false;
    this.editingPlanId = 0;
    this.undoTasks = [];
    this.pendingRestoreMovePlanIds = [];
    this.refreshTask = null;
    this.planItemMap = new Map<number, PlanItem>();
  }

  clearListCache(): void {
    this.plans = [];
    this.visiblePlans = [];
    this.visiblePlanCards = [];
    this.pendingRestoreMovePlanIds = [];
    this.refreshTask = null;
    this.planItemMap = new Map<number, PlanItem>();
  }
}

const PLAN_PAGE_STATE: PlanPageState = new PlanPageState();

export function usePlanPageState(): PlanPageState {
  return PLAN_PAGE_STATE;
}
