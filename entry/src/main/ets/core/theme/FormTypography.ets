/**
 * 组件功能简介：
 * - 表单字体尺寸常量集合，统一定义表单各层级文本字号。
 *
 * 可传入项：
 * - 无。
 *
 * 返回行为：
 * - 通过静态常量提供标题、标签、输入内容等字号配置。
 *
 * 副作用：
 * - 无。
 */
export class FormTypography {
  static readonly TITLE_SIZE: number = 18;
  static readonly LABEL_SIZE: number = 16;
  static readonly INPUT_CONTENT_SIZE: number = 16;
  static readonly SELECT_CONTENT_SIZE: number = 14;
  static readonly INFO_SIZE: number = 14;
}
