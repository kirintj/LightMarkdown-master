import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { MarkdownFile, FileGroup } from '../class/MarkdownFile';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'md_files.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_FILES_TABLE = `CREATE TABLE IF NOT EXISTS markdown_files (
  sandboxPath TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  uri TEXT DEFAULT '',
  size TEXT DEFAULT '',
  isStar INTEGER DEFAULT 0,
  groupId INTEGER DEFAULT -1
)`;

const SQL_CREATE_GROUPS_TABLE = `CREATE TABLE IF NOT EXISTS file_groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  createdAt INTEGER NOT NULL
)`;

const SQL_ADD_GROUP_ID = `ALTER TABLE markdown_files ADD COLUMN groupId INTEGER DEFAULT -1`;
const SQL_ADD_LAST_VIEWED_AT = `ALTER TABLE markdown_files ADD COLUMN lastViewedAt INTEGER DEFAULT 0`;
const SQL_ADD_CREATED_AT = `ALTER TABLE markdown_files ADD COLUMN createdAt INTEGER DEFAULT 0`;

export class MdDbService {
  private static instance: MdDbService | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.UIAbilityContext;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  static getInstance(context: common.UIAbilityContext): MdDbService {
    if (!MdDbService.instance) {
      MdDbService.instance = new MdDbService(context);
    }
    return MdDbService.instance;
  }

  async init(): Promise<void> {
    if (this.rdbStore !== null) return;
    try {
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
      await this.rdbStore.executeSql(SQL_CREATE_FILES_TABLE);
      await this.rdbStore.executeSql(SQL_CREATE_GROUPS_TABLE);
      await this.upgradeIfNeeded();
    } catch (error) {
      console.log('A')
    }
  }

  private async upgradeIfNeeded(): Promise<void> {
    const store = this.rdbStore!;
    try {
      const predicates = new relationalStore.RdbPredicates('markdown_files');
      const resultSet = await store.query(predicates);
      const columns = resultSet.columnNames;
      const hasGroupId = columns.includes('groupId');
      const hasLastViewedAt = columns.includes('lastViewedAt');
      const hasCreatedAt = columns.includes('createdAt');
      resultSet.close();
      if (!hasGroupId) {
        await store.executeSql(SQL_ADD_GROUP_ID);
      }
      if (!hasLastViewedAt) {
        await store.executeSql(SQL_ADD_LAST_VIEWED_AT);
      }
      if (!hasCreatedAt) {
        await store.executeSql(SQL_ADD_CREATED_AT);
      }
    } catch (err) {
      console.error('[MdDbService] 升级检查失败:', JSON.stringify(err));
    }
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('[MdDbService] 数据库未初始化，请先调用 init()');
    }
    return this.rdbStore;
  }

  async insertFile(file: MarkdownFile): Promise<number> {
    const store = this.ensureStore();
    const value: relationalStore.ValuesBucket = {
      sandboxPath: file.sandboxPath,
      name: file.name,
      uri: file.uri,
      size: file.size,
      isStar: file.isStar ? 1 : 0,
      groupId: file.groupId,
      lastViewedAt: file.lastViewedAt,
      createdAt: file.createdAt
    };
    return store.insert('markdown_files', value, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async insertFiles(files: MarkdownFile[]): Promise<void> {
    const store = this.ensureStore();
    const transaction = await store.createTransaction();
    try {
      for (const file of files) {
        const value: relationalStore.ValuesBucket = {
          sandboxPath: file.sandboxPath,
          name: file.name,
          uri: file.uri,
          size: file.size,
          isStar: file.isStar ? 1 : 0,
          groupId: file.groupId,
          lastViewedAt: file.lastViewedAt,
          createdAt: file.createdAt
        };
        await store.insert('markdown_files', value, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      }
      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      console.error('[MdDbService] 批量插入失败:', JSON.stringify(err));
    }
  }

  async deleteFile(sandboxPath: string): Promise<number> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', sandboxPath);
    return store.delete(predicates);
  }

  async toggleStar(sandboxPath: string): Promise<boolean> {
    const store = this.ensureStore();
    const current = await this.queryByPath(sandboxPath);
    if (!current) return false;
    const newStar = current.isStar ? 0 : 1;
    const value: relationalStore.ValuesBucket = { isStar: newStar };
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', sandboxPath);
    await store.update(value, predicates);
    return newStar === 1;
  }

  async setStar(sandboxPath: string, isStar: boolean): Promise<void> {
    const store = this.ensureStore();
    const value: relationalStore.ValuesBucket = { isStar: isStar ? 1 : 0 };
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', sandboxPath);
    await store.update(value, predicates);
  }

  async setFileGroup(sandboxPath: string, groupId: number): Promise<void> {
    const store = this.ensureStore();
    const value: relationalStore.ValuesBucket = { groupId: groupId };
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', sandboxPath);
    await store.update(value, predicates);
  }

  async removeFileGroup(sandboxPath: string): Promise<void> {
    await this.setFileGroup(sandboxPath, -1);
  }

  async renameFile(oldPath: string, newName: string): Promise<string> {
    // 校验新文件名
    if (!newName.trim()) {
      throw new Error('文件名不能为空');
    }
    if (!newName.endsWith('.md')) {
      throw new Error('文件名必须以 .md 结尾');
    }
    const illegalChars = /[\\/:*?"<>|]/;
    if (illegalChars.test(newName)) {
      throw new Error('文件名包含非法字符');
    }

    const store = this.ensureStore();
    const lastSlash = oldPath.lastIndexOf('/');
    const newDir = oldPath.substring(0, lastSlash + 1);
    const newPath = newDir + newName;

    // 检查是否重名（且不是自身）
    if (oldPath !== newPath) {
      const existing = await this.queryByPath(newPath);
      if (existing) {
        throw new Error('已存在同名文件');
      }
      // 重命名文件系统文件
      fs.renameSync(oldPath, newPath);
    }

    // 更新数据库
    const value: relationalStore.ValuesBucket = {
      sandboxPath: newPath,
      name: newName
    };
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', oldPath);
    await store.update(value, predicates);

    return newPath;
  }

  async queryAll(): Promise<MarkdownFile[]> {
    await this.refreshGroupCache();
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    const resultSet = await store.query(predicates);
    return this.parseResultSet(resultSet);
  }

  async queryStarred(): Promise<MarkdownFile[]> {
    await this.refreshGroupCache();
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('isStar', 1);
    const resultSet = await store.query(predicates);
    return this.parseResultSet(resultSet);
  }

  async queryByPath(sandboxPath: string): Promise<MarkdownFile | null> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', sandboxPath);
    const resultSet = await store.query(predicates);
    const list = this.parseResultSet(resultSet);
    return list.length > 0 ? list[0] : null;
  }

  async queryByGroup(groupId: number): Promise<MarkdownFile[]> {
    await this.refreshGroupCache();
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('groupId', groupId);
    const resultSet = await store.query(predicates);
    return this.parseResultSet(resultSet);
  }

  async queryUngrouped(): Promise<MarkdownFile[]> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('groupId', -1);
    const resultSet = await store.query(predicates);
    return this.parseResultSet(resultSet);
  }

  async getStarCount(): Promise<number> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('isStar', 1);
    const resultSet = await store.query(predicates);
    const count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  async getTotalCount(): Promise<number> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    const resultSet = await store.query(predicates);
    const count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  async getGroupCount(): Promise<number> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('file_groups');
    const resultSet = await store.query(predicates);
    const count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  async updateLastViewedAt(sandboxPath: string): Promise<void> {
    const store = this.ensureStore();
    const value: relationalStore.ValuesBucket = { lastViewedAt: Date.now() };
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('sandboxPath', sandboxPath);
    await store.update(value, predicates);
  }

  async queryRecentlyViewed(limit: number = 50): Promise<MarkdownFile[]> {
    await this.refreshGroupCache();
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.greaterThan('lastViewedAt', 0);
    predicates.orderByDesc('lastViewedAt');
    predicates.limitAs(limit);
    const resultSet = await store.query(predicates);
    return this.parseResultSet(resultSet);
  }

  async getRecentlyViewedCount(): Promise<number> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.greaterThan('lastViewedAt', 0);
    const resultSet = await store.query(predicates);
    const count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  async syncFromFileSystem(files: MarkdownFile[]): Promise<void> {
    const store = this.ensureStore();
    const dbFiles = await this.queryAll();
    const dbPathSet = new Set(dbFiles.map(f => f.sandboxPath));
    const fsPathSet = new Set(files.map(f => f.sandboxPath));

    const transaction = await store.createTransaction();
    try {
      for (const file of files) {
        if (!dbPathSet.has(file.sandboxPath)) {
          await this.insertFile(file);
        }
      }
      for (const dbFile of dbFiles) {
        if (!fsPathSet.has(dbFile.sandboxPath)) {
          await this.deleteFile(dbFile.sandboxPath);
        }
      }
      await transaction.commit();
    } catch (err) {
      await transaction.rollback();
      console.error('[MdDbService] 同步失败:', JSON.stringify(err));
    }
  }

  // ========== 分组 CRUD ==========

  async createGroup(name: string): Promise<number> {
    const store = this.ensureStore();
    const value: relationalStore.ValuesBucket = {
      name: name,
      createdAt: Date.now()
    };
    const id = await store.insert('file_groups', value);
    await this.refreshGroupCache();
    return id;
  }

  async deleteGroup(groupId: number): Promise<void> {
    const store = this.ensureStore();
    const transaction = await store.createTransaction();
    try {
      const fileValue: relationalStore.ValuesBucket = { groupId: -1 };
      const filePredicates = new relationalStore.RdbPredicates('markdown_files');
      filePredicates.equalTo('groupId', groupId);
      await store.update(fileValue, filePredicates);

      const groupPredicates = new relationalStore.RdbPredicates('file_groups');
      groupPredicates.equalTo('id', groupId);
      await store.delete(groupPredicates);

      await transaction.commit();
      await this.refreshGroupCache();
    } catch (err) {
      await transaction.rollback();
      console.error('[MdDbService] 删除分组失败:', JSON.stringify(err));
    }
  }

  async renameGroup(groupId: number, newName: string): Promise<void> {
    const store = this.ensureStore();
    const value: relationalStore.ValuesBucket = { name: newName };
    const predicates = new relationalStore.RdbPredicates('file_groups');
    predicates.equalTo('id', groupId);
    await store.update(value, predicates);
  }

  async queryAllGroups(): Promise<FileGroup[]> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('file_groups');
    predicates.orderByDesc('createdAt');
    const resultSet = await store.query(predicates);
    return this.parseGroupResultSet(resultSet);
  }

  async queryGroupById(groupId: number): Promise<FileGroup | null> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('file_groups');
    predicates.equalTo('id', groupId);
    const resultSet = await store.query(predicates);
    const list = this.parseGroupResultSet(resultSet);
    return list.length > 0 ? list[0] : null;
  }

  async getGroupFileCount(groupId: number): Promise<number> {
    const store = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('markdown_files');
    predicates.equalTo('groupId', groupId);
    const resultSet = await store.query(predicates);
    const count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  private parseResultSet(resultSet: relationalStore.ResultSet): MarkdownFile[] {
    const result: MarkdownFile[] = [];
    if (resultSet.rowCount <= 0) {
      resultSet.close();
      return result;
    }
    const groups = this.getGroupMap();
    resultSet.goToFirstRow();
    do {
      const sandboxPath = resultSet.getString(resultSet.getColumnIndex('sandboxPath'));
      const name = resultSet.getString(resultSet.getColumnIndex('name'));
      const uri = resultSet.getString(resultSet.getColumnIndex('uri'));
      const size = resultSet.getString(resultSet.getColumnIndex('size'));
      const isStar = resultSet.getLong(resultSet.getColumnIndex('isStar')) === 1;
      let groupId = -1;
      try {
        groupId = resultSet.getLong(resultSet.getColumnIndex('groupId'));
      } catch (e) {
        groupId = -1;
      }
      let lastViewedAt = 0;
      try {
        lastViewedAt = resultSet.getLong(resultSet.getColumnIndex('lastViewedAt'));
      } catch (e) {
        lastViewedAt = 0;
      }
      let createdAt = 0;
      try {
        createdAt = resultSet.getLong(resultSet.getColumnIndex('createdAt'));
      } catch (e) {
        createdAt = 0;
      }
      const groupName = groups.get(groupId) ?? '';
      result.push(new MarkdownFile(name, uri, sandboxPath, 0, isStar, size, groupId, groupName, lastViewedAt, createdAt));
    } while (resultSet.goToNextRow());
    resultSet.close();
    return result;
  }

  private groupCache: Map<number, string> = new Map();

  private getGroupMap(): Map<number, string> {
    return this.groupCache;
  }

  async refreshGroupCache(): Promise<void> {
    const groups = await this.queryAllGroups();
    this.groupCache.clear();
    for (const g of groups) {
      this.groupCache.set(g.id, g.name);
    }
  }

  private parseGroupResultSet(resultSet: relationalStore.ResultSet): FileGroup[] {
    const result: FileGroup[] = [];
    if (resultSet.rowCount <= 0) {
      resultSet.close();
      return result;
    }
    resultSet.goToFirstRow();
    do {
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      const name = resultSet.getString(resultSet.getColumnIndex('name'));
      const createdAt = resultSet.getLong(resultSet.getColumnIndex('createdAt'));
      result.push(new FileGroup(id, name, createdAt));
    } while (resultSet.goToNextRow());
    resultSet.close();
    return result;
  }
}
