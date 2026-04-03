/**
 * 数据导入导出服务占位。
 * TODO: 后续补充 ICS/CSV 解析和本地文件读写。
 */
export class ImportExportService {
  importFromFile(path: string): Promise<void> {
    // TODO: 识别文件格式并导入数据。
    return Promise.resolve();
  }

  exportToFile(path: string): Promise<void> {
    // TODO: 按选定格式导出本地数据。
    return Promise.resolve();
  }
}
