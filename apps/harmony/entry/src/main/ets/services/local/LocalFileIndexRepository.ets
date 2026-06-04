import { relationalStore } from '@kit.ArkData';
import { appRdbStore } from '../../common/AppRdbStore';
import { TransferItemType } from '../../models/CommonTypes';
import { LocalFileEntry } from '../../models/LocalFileEntry';

export interface LocalFileIndexRepository {
  list(): LocalFileEntry[];
  listByType(type: TransferItemType): LocalFileEntry[];
  findById(id: string): LocalFileEntry | undefined;
  save(file: LocalFileEntry): void;
  remove(ids: string[]): void;
}

export class RuntimeLocalFileIndexRepository implements LocalFileIndexRepository {
  private files: LocalFileEntry[] = [];

  list(): LocalFileEntry[] {
    return this.sortByImportedAtDesc(this.copyFiles(this.files));
  }

  listByType(type: TransferItemType): LocalFileEntry[] {
    return this.sortByImportedAtDesc(this.copyFiles(this.files.filter((file) => file.type === type)));
  }

  findById(id: string): LocalFileEntry | undefined {
    const file = this.files.find((next) => next.id === id);
    if (file === undefined) {
      return undefined;
    }
    return this.copyFile(file);
  }

  save(file: LocalFileEntry): void {
    const nextFile = this.copyFile(file);
    const index = this.files.findIndex((next) => next.id === file.id);
    if (index < 0) {
      this.files.push(nextFile);
      return;
    }
    this.files[index] = nextFile;
  }

  remove(ids: string[]): void {
    this.files = this.files.filter((file) => !ids.includes(file.id));
  }

  private copyFiles(source: LocalFileEntry[]): LocalFileEntry[] {
    const files: LocalFileEntry[] = [];
    source.forEach((file: LocalFileEntry) => {
      files.push(this.copyFile(file));
    });
    return files;
  }

  private copyFile(file: LocalFileEntry): LocalFileEntry {
    return {
      id: file.id,
      displayName: file.displayName,
      type: file.type,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      localUri: file.localUri,
      lastSharedAt: file.lastSharedAt,
      shareCount: file.shareCount,
      remoteCached: file.remoteCached,
      encrypted: file.encrypted
    };
  }

  private sortByImportedAtDesc(files: LocalFileEntry[]): LocalFileEntry[] {
    return files.sort((left: LocalFileEntry, right: LocalFileEntry) => this.resolveImportedAt(right) - this.resolveImportedAt(left));
  }

  private resolveImportedAt(file: LocalFileEntry): number {
    const fromId = this.parseFirstNumber(file.id);
    if (fromId > 0) {
      return fromId;
    }
    return this.parseFirstNumber(file.localUri);
  }

  private parseFirstNumber(value: string): number {
    const matches = value.match(/\d{10,}/);
    if (matches === null || matches.length === 0) {
      return 0;
    }
    return Number(matches[0]);
  }
}

const CREATE_LOCAL_FILES_SQL: string = `
create table if not exists local_files (
  id text primary key,
  display_name text not null,
  type text not null,
  content_type text not null,
  size_bytes integer not null,
  local_uri text not null,
  last_shared_at text,
  share_count integer not null,
  remote_cached integer not null,
  encrypted integer not null
)`;

export class RdbLocalFileIndexRepository implements LocalFileIndexRepository {
  private files: LocalFileEntry[] = [];
  private initialized: boolean = false;

  list(): LocalFileEntry[] {
    this.ensureInitialized();
    return this.sortByImportedAtDesc(this.copyFiles(this.files));
  }

  listByType(type: TransferItemType): LocalFileEntry[] {
    this.ensureInitialized();
    return this.sortByImportedAtDesc(this.copyFiles(this.files.filter((file) => file.type === type)));
  }

  findById(id: string): LocalFileEntry | undefined {
    this.ensureInitialized();
    const file = this.files.find((next) => next.id === id);
    if (file === undefined) {
      return undefined;
    }
    return this.copyFile(file);
  }

  save(file: LocalFileEntry): void {
    this.ensureInitialized();
    const nextFile = this.copyFile(file);
    const index = this.files.findIndex((next) => next.id === file.id);
    if (index < 0) {
      this.files.push(nextFile);
    } else {
      this.files[index] = nextFile;
    }
    this.persistFile(nextFile);
  }

  remove(ids: string[]): void {
    this.ensureInitialized();
    this.files = this.files.filter((file) => !ids.includes(file.id));
    const store = appRdbStore.getStore();
    if (store === undefined) {
      return;
    }
    ids.forEach((id: string) => {
      const predicates = new relationalStore.RdbPredicates('local_files');
      predicates.equalTo('id', id);
      store.delete(predicates).catch((error: Error) => {
        console.error(`[CourseDrop] delete local file index failed: ${String(error)}`);
      });
    });
  }

  private ensureInitialized(): void {
    if (this.initialized) {
      return;
    }
    this.initialized = true;
    const store = appRdbStore.getStore();
    if (store === undefined) {
      return;
    }
    try {
      store.execute(CREATE_LOCAL_FILES_SQL).then(() => {
        this.loadAll();
      }).catch((error: Error) => {
        console.error(`[CourseDrop] create local_files table failed: ${String(error)}`);
      });
      this.loadAll();
    } catch (error) {
      console.error(`[CourseDrop] initialize local file index failed: ${String(error)}`);
    }
  }

  private loadAll(): void {
    const store = appRdbStore.getStore();
    if (store === undefined) {
      return;
    }
    try {
      const resultSet = store.querySqlSync('select * from local_files order by rowid desc');
      while (resultSet.goToNextRow()) {
        const id = resultSet.getValue(resultSet.getColumnIndex('id')) as string;
        if (this.files.some((f) => f.id === id)) {
          continue;
        }
        this.files.push({
          id: id,
          displayName: resultSet.getValue(resultSet.getColumnIndex('display_name')) as string,
          type: resultSet.getValue(resultSet.getColumnIndex('type')) as TransferItemType,
          contentType: resultSet.getValue(resultSet.getColumnIndex('content_type')) as string,
          sizeBytes: resultSet.getValue(resultSet.getColumnIndex('size_bytes')) as number,
          localUri: resultSet.getValue(resultSet.getColumnIndex('local_uri')) as string,
          lastSharedAt: resultSet.getValue(resultSet.getColumnIndex('last_shared_at')) as string,
          shareCount: resultSet.getValue(resultSet.getColumnIndex('share_count')) as number,
          remoteCached: (resultSet.getValue(resultSet.getColumnIndex('remote_cached')) as number) === 1,
          encrypted: (resultSet.getValue(resultSet.getColumnIndex('encrypted')) as number) === 1
        });
      }
      resultSet.close();
    } catch (error) {
      console.error(`[CourseDrop] load local file index failed: ${String(error)}`);
    }
  }

  private persistFile(file: LocalFileEntry): void {
    const store = appRdbStore.getStore();
    if (store === undefined) {
      return;
    }
    const values: relationalStore.ValuesBucket = {
      'id': file.id,
      'display_name': file.displayName,
      'type': file.type,
      'content_type': file.contentType,
      'size_bytes': file.sizeBytes,
      'local_uri': file.localUri,
      'last_shared_at': file.lastSharedAt === undefined ? '' : file.lastSharedAt,
      'share_count': file.shareCount,
      'remote_cached': file.remoteCached ? 1 : 0,
      'encrypted': file.encrypted ? 1 : 0
    };
    store.insert('local_files', values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
      .catch((error: Error) => {
        console.error(`[CourseDrop] save local file index failed: ${String(error)}`);
      });
  }

  private copyFiles(source: LocalFileEntry[]): LocalFileEntry[] {
    const files: LocalFileEntry[] = [];
    source.forEach((file: LocalFileEntry) => {
      files.push(this.copyFile(file));
    });
    return files;
  }

  private copyFile(file: LocalFileEntry): LocalFileEntry {
    return {
      id: file.id,
      displayName: file.displayName,
      type: file.type,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      localUri: file.localUri,
      lastSharedAt: file.lastSharedAt,
      shareCount: file.shareCount,
      remoteCached: file.remoteCached,
      encrypted: file.encrypted
    };
  }

  private sortByImportedAtDesc(files: LocalFileEntry[]): LocalFileEntry[] {
    return files.sort((left: LocalFileEntry, right: LocalFileEntry) => this.resolveImportedAt(right) - this.resolveImportedAt(left));
  }

  private resolveImportedAt(file: LocalFileEntry): number {
    const fromId = this.parseFirstNumber(file.id);
    if (fromId > 0) {
      return fromId;
    }
    return this.parseFirstNumber(file.localUri);
  }

  private parseFirstNumber(value: string): number {
    const matches = value.match(/\d{10,}/);
    if (matches === null || matches.length === 0) {
      return 0;
    }
    return Number(matches[0]);
  }
}
