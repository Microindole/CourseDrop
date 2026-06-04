import { LocalFileEntry } from '../../models/LocalFileEntry';
import { CourseDropFileStore } from '../local/CourseDropFileStore';
import { LocalFileIndexRepository } from '../local/LocalFileIndexRepository';
import { FileImportPlan, FileImportResult, PickedFile } from './FileModels';
import { FileSystemService } from './FileSystemService';

export interface FileImportService {
  createImportPlan(file: PickedFile): FileImportPlan;
  importPickedFile(file: PickedFile): Promise<FileImportResult>;
}

export class CourseDropFileImportService implements FileImportService {
  private fileStore: CourseDropFileStore;
  private indexRepository: LocalFileIndexRepository;
  private fileSystemService: FileSystemService;

  constructor(
    fileStore: CourseDropFileStore,
    indexRepository: LocalFileIndexRepository,
    fileSystemService: FileSystemService
  ) {
    this.fileStore = fileStore;
    this.indexRepository = indexRepository;
    this.fileSystemService = fileSystemService;
  }

  createImportPlan(file: PickedFile): FileImportPlan {
    return {
      sourceUri: file.uri,
      displayName: file.displayName,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      type: file.type,
      targetDirectory: this.fileStore.stagingRoot()
    };
  }

  async importPickedFile(file: PickedFile): Promise<FileImportResult> {
    const targetDirectory = this.fileStore.libraryRoot();
    if (targetDirectory.length === 0) {
      throw new Error('应用沙箱目录未初始化');
    }
    const displayName = this.createUniqueDisplayName(file.displayName);
    const copiedFile = this.fileSystemService.copyToDirectory(file.uri, targetDirectory, displayName);
    const localFileId = `local-${Date.now()}`;
    const entry: LocalFileEntry = {
      id: localFileId,
      displayName: displayName,
      type: file.type,
      contentType: file.contentType,
      sizeBytes: copiedFile.sizeBytes,
      localUri: copiedFile.path,
      shareCount: 0,
      remoteCached: false,
      encrypted: false
    };
    this.indexRepository.save(entry);
    return {
      localFileId: localFileId,
      localUri: copiedFile.path
    };
  }

  private createUniqueDisplayName(displayName: string): string {
    const existingNames = this.indexRepository.list().map((file: LocalFileEntry) => file.displayName);
    if (!existingNames.includes(displayName)) {
      return displayName;
    }
    const extensionIndex = displayName.lastIndexOf('.');
    const hasExtension = extensionIndex > 0 && extensionIndex < displayName.length - 1;
    const baseName = hasExtension ? displayName.substring(0, extensionIndex) : displayName;
    const extension = hasExtension ? displayName.substring(extensionIndex) : '';
    let suffix = 1;
    let candidate = `${baseName}(${suffix})${extension}`;
    while (existingNames.includes(candidate)) {
      suffix += 1;
      candidate = `${baseName}(${suffix})${extension}`;
    }
    return candidate;
  }
}
