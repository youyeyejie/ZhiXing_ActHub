export class ArrayDataSource<T> implements IDataSource {
  private listeners: Array<DataChangeListener> = [];
  private items: Array<T> = [];
  totalCount(): number {
    return this.items.length;
  }
  getData(index: number): T {
    return this.items[index];
  }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) >= 0) {
      return;
    }
    this.listeners.push(listener);
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const listenerIndex = this.listeners.indexOf(listener);
    if (listenerIndex < 0) {
      return;
    }
    this.listeners.splice(listenerIndex, 1);
  }
  updateItems(items: Array<T>): void {
    this.items = items.slice();
    this.notifyDataReload();
  }
  private notifyDataReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }
}