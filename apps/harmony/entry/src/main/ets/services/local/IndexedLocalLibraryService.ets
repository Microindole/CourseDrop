import { fileIo } from '@kit.CoreFileKit';
import { TransferItemType } from '../../models/CommonTypes';
import { LocalFileEntry } from '../../models/LocalFileEntry';
import { CourseDropFileStore } from './CourseDropFileStore';
import { LocalFileIndexRepository } from './LocalFileIndexRepository';
import { LocalLibraryService } from './LocalLibraryService';

export class IndexedLocalLibraryService implements LocalLibraryService {
  private fileStore: CourseDropFileStore;
  private indexRepository: LocalFileIndexRepository;

  constructor(
    fileStore: CourseDropFileStore,
    indexRepository: LocalFileIndexRepository
  ) {
    this.fileStore = fileStore;
    this.indexRepository = indexRepository;
  }

  getLibraryRoot(): string {
    return this.fileStore.libraryRoot();
  }

  listFiles(): LocalFileEntry[] {
    return this.cleanupMissingFiles(this.indexRepository.list());
  }

  listByType(type: TransferItemType): LocalFileEntry[] {
    return this.listFiles().filter((file: LocalFileEntry) => file.type === type);
  }

  markShared(ids: string[]): void {
    this.indexRepository.list().forEach((file) => {
      if (ids.includes(file.id)) {
        file.shareCount = file.shareCount + 1;
        file.remoteCached = true;
        this.indexRepository.save(file);
      }
    });
  }

  removeFiles(ids: string[]): void {
    this.indexRepository.remove(ids);
  }

  private cleanupMissingFiles(files: LocalFileEntry[]): LocalFileEntry[] {
    const existingFiles: LocalFileEntry[] = [];
    const missingIds: string[] = [];
    files.forEach((file: LocalFileEntry) => {
      if (this.fileExists(file.localUri)) {
        existingFiles.push(file);
      } else {
        missingIds.push(file.id);
      }
    });
    if (missingIds.length > 0) {
      this.indexRepository.remove(missingIds);
      console.warn(`[CourseDrop] removed missing local library files: ${missingIds.join(',')}`);
    }
    return existingFiles;
  }

  private fileExists(uri: string): boolean {
    try {
      const stat = fileIo.statSync(this.toLocalPath(uri));
      return stat.size > 0;
    } catch (_error) {
      return false;
    }
  }

  private toLocalPath(uri: string): string {
    if (!uri.startsWith('file://')) {
      return uri;
    }
    return decodeURIComponent(uri.replace(/^file:\/\//, ''));
  }
}
