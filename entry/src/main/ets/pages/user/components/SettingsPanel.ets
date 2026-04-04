/**
 * 设置面板骨架。
 * TODO: 后续放入主题切换、提醒开关、导入导出和退出登录入口。
 */
@ComponentV2
export struct SettingsPanel {
  build() {
    Column({ space: 8 }) {
      Text('SettingsPanel')
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text('TODO: 汇总系统设置项。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#FFFFFF');
  }
}
