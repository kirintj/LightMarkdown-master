export class FileGroup {
  id: number;
  name: string;
  createdAt: number;

  constructor(id: number, name: string, createdAt: number = Date.now()) {
    this.id = id;
    this.name = name;
    this.createdAt = createdAt;
  }
}

@Observed
export class MarkdownFile {
  name: string;
  uri: string;
  sandboxPath: string;
  size: string;
  isStar: boolean;
  groupId: number;
  groupName: string;
  lastViewedAt: number;
  createdAt: number;

  constructor(name: string, uri: string, sandboxPath: string, size: number, isStar: boolean = false, formattedSize?: string, groupId: number = -1, groupName: string = '', lastViewedAt: number = 0, createdAt: number = 0) {
    this.name = name;
    this.uri = uri;
    this.sandboxPath = sandboxPath;
    this.size = formattedSize ?? (size / 1024).toFixed(2) + ' KB';
    this.isStar = isStar;
    this.groupId = groupId;
    this.groupName = groupName;
    this.lastViewedAt = lastViewedAt;
    this.createdAt = createdAt;
  }
}
export class FileDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private dataArray: MarkdownFile[] = [];

  public totalCount(): number { return this.dataArray.length; }
  public getData(index: number): MarkdownFile { return this.dataArray[index]; }
  public getIndex(item: MarkdownFile): number {
    return this.dataArray.indexOf(item);
  }
  public getIndexByPath(sandboxPath: string): number {
    return this.dataArray.findIndex(f => f.sandboxPath === sandboxPath);
  }
  public pushItem(item: MarkdownFile): void {
    this.dataArray.push(item);
    this.notifyDataAdd(this.dataArray.length - 1);
  }
  public removeItem(index: number): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray.splice(index, 1);
      this.notifyDataDelete(index);
    }
  }
  public updateItemStar(sandboxPath: string, isStar: boolean): void {
    const index = this.getIndexByPath(sandboxPath);
    if (index >= 0) {
      this.dataArray[index].isStar = isStar;
      this.notifyDataChange(index);
    }
  }
  public updateItemGroup(sandboxPath: string, groupId: number, groupName: string): void {
    const index = this.getIndexByPath(sandboxPath);
    if (index >= 0) {
      this.dataArray[index].groupId = groupId;
      this.dataArray[index].groupName = groupName;
      this.notifyDataChange(index);
    }
  }
  public updateItemPath(oldPath: string, newName: string, newPath: string): void {
    const index = this.getIndexByPath(oldPath);
    if (index >= 0) {
      this.dataArray[index].name = newName;
      this.dataArray[index].sandboxPath = newPath;
      this.notifyDataChange(index);
    }
  }
  public removeItemGroup(groupId: number): void {
    for (let i = 0; i < this.dataArray.length; i++) {
      if (this.dataArray[i].groupId === groupId) {
        this.dataArray[i].groupId = -1;
        this.dataArray[i].groupName = '';
        this.notifyDataChange(i);
      }
    }
  }
  public clear(): void {
    const oldCount = this.dataArray.length;
    this.dataArray = [];
    for (let i = oldCount - 1; i >= 0; i--) {
      this.notifyDataDelete(i);
    }
  }
  public getAll(): ReadonlyArray<MarkdownFile> {
    return this.dataArray;
  }

  registerDataChangeListener(l: DataChangeListener): void {
    if (this.listeners.indexOf(l) < 0) {
      this.listeners.push(l);
    }
  }

  unregisterDataChangeListener(l: DataChangeListener): void {
    const index = this.listeners.indexOf(l);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  notifyDataAdd(index: number): void { this.listeners.forEach(l => l.onDataAdd(index)); }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(l => l.onDataDelete(index));
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => listener.onDataChange(index));
  }
}