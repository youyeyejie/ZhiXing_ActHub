/**
 * TodoPickerSheet 模块统一样式配置。
 * 调整此处可统一修改待办选择器内的卡片布局、字体和间距。
 */
export class TodoPickerStyle {
  // 布局间距
  static readonly ROW_SPACE: number = 8;
  static readonly COLUMN_SPACE_LARGE: number = 12;
  static readonly COLUMN_SPACE_SMALL: number = 6;
  static readonly CARD_PADDING: number = 12;
  static readonly BOTTOM_PADDING: number = 24;
  
  // 字体大小
  static readonly HEADER_FONT_SIZE: number = 16;
  static readonly SUB_HEADER_FONT_SIZE: number = 13;
  static readonly TITLE_FONT_SIZE: number = 15;
  static readonly INFO_FONT_SIZE: number = 12;
  static readonly ICON_SIZE: number = 18;
  
  // 卡片装饰
  static readonly CARD_BORDER_RADIUS: number = 14;
  static readonly INDICATOR_DOT_SIZE: number = 8;
}