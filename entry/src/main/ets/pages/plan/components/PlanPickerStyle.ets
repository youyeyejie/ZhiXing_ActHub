/**
 * Plan 模块日期时间弹窗与触发器统一样式配置。
 * 调整一处即可同步新建/编辑中的 DatePickerDialog 参数与外观。
 */
export class PlanPickerStyle {
  static readonly PANEL_HEIGHT: number = 53;
  static readonly ROW_SPACE: number = 8;
  static readonly TRIGGER_WIDTH: number = 190;
  static readonly CONTENT_SCALE_Y: number = 0.84;
  static readonly DATE_RANGE_START: string = '2000-1-1';
  static readonly DATE_RANGE_END: string = '2100-12-31';
  static readonly DISAPPEAR_FONT_SIZE: string = '10fp';
  static readonly TEXT_FONT_SIZE: string = '12fp';
  static readonly SELECTED_FONT_SIZE: string = '15fp';
}
