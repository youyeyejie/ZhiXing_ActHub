/**
 * 组件功能简介：
 * - 通用内容流容器，负责按批次增量渲染列表内容，降低首屏渲染压力。
 *
 * 可传入项：
 * - `totalCount`：总条目数。
 * - `batchSize`：每次增量渲染的条目数。
 * - `space`：条目间距。
 * - `itemBuilder(index)`：按索引构建条目。
 *
 * 返回行为：
 * - 返回支持懒加载扩容的纵向内容流。
 *
 * 副作用：
 * - 底部哨兵出现在视口时会提升 `visibleCount`。
 */
@ComponentV2
export struct ContentFlow {
  @Param totalCount: number = 0;
  @Param batchSize: number = 12;
  @Param space: number = 12;
  @BuilderParam itemBuilder: (index: number) => void = this.buildEmptyItem;
  @Local private visibleCount: number = 0;

  aboutToAppear(): void {
    this.resetVisibleCount();
  }

  @Monitor('totalCount')
  onTotalCountChanged(): void {
    this.resetVisibleCount();
  }

  @Builder
  private buildEmptyItem(_index: number) {}

  private resolveBatchSize(): number {
    return this.batchSize > 0 ? this.batchSize : 12;
  }

  private resetVisibleCount(): void {
    const initialCount: number = Math.min(this.totalCount, this.resolveBatchSize());
    this.visibleCount = initialCount > 0 ? initialCount : 0;
  }

  private loadMore(): void {
    if (this.visibleCount >= this.totalCount) {
      return;
    }
    this.visibleCount = Math.min(this.totalCount, this.visibleCount + this.resolveBatchSize());
  }

  private buildIndexList(): Array<number> {
    const indices: Array<number> = [];
    for (let index = 0; index < this.visibleCount; index++) {
      indices.push(index);
    }
    return indices;
  }

  build() {
    Column({ space: this.space }) {
      ForEach(
        this.buildIndexList(),
        (index: number) => {
          this.itemBuilder(index);
        },
        (index: number) => `content_flow_${index}`,
      )

      if (this.visibleCount < this.totalCount) {
        Blank()
          .width('100%')
          .height(1)
          .onAppear(() => {
            this.loadMore();
          })
      }
    }
    .width('100%');
  }
}
