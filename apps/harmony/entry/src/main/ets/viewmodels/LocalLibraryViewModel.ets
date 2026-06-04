import { TransferItemType } from '../models/CommonTypes';
import { LocalFileEntry } from '../models/LocalFileEntry';
import { localLibraryService } from '../services/local';
import { localFileImportWorkflow } from '../services/file';
import { shareService } from '../services/share';

export type LocalLibraryFilter = 'ALL' | TransferItemType;

export class LocalLibraryViewModel {
  loadFiles(): LocalFileEntry[] {
    return localLibraryService.listFiles();
  }

  getFilteredFiles(files: LocalFileEntry[], filter: LocalLibraryFilter, keyword: string): LocalFileEntry[] {
    return files.filter((file) => {
      let matchesKeyword = keyword.length === 0 ||
        file.displayName.toLowerCase().includes(keyword.toLowerCase());
      let matchesFilter = filter === 'ALL' || file.type === filter;
      return matchesKeyword && matchesFilter;
    });
  }

  async importFiles(type?: TransferItemType): Promise<string> {
    const result = await localFileImportWorkflow.importFiles(type);
    return result.message;
  }

  createDebugTextFile(): string {
    const result = localFileImportWorkflow.createDebugTextFile();
    return result.message;
  }

  shareSelected(selectedIds: string[]): string {
    let attachedCount = 0;
    let session = shareService.getCurrentSession();
    if (session.status !== 'DRAFT') {
      shareService.returnToDraft(session.id);
      session = shareService.getCurrentSession();
    }
    for (let index = 0; index < selectedIds.length; index += 1) {
      const result = shareService.attachLocalFile(session.id, selectedIds[index]);
      if (result.success) {
        attachedCount += 1;
      }
    }
    localLibraryService.markShared(selectedIds);
    return attachedCount > 0 ? `已加入分享草稿 ${attachedCount} 项` : '所选内容已在分享草稿中';
  }

  getFilesByIds(selectedIds: string[]): LocalFileEntry[] {
    const files = this.loadFiles();
    const selectedFiles: LocalFileEntry[] = [];
    selectedIds.forEach((id: string) => {
      const file = files.find((item: LocalFileEntry) => item.id === id);
      if (file !== undefined) {
        selectedFiles.push(file);
      }
    });
    return selectedFiles;
  }

  deleteSelected(selectedIds: string[]): string {
    const selectedCount = selectedIds.length;
    localLibraryService.removeFiles(selectedIds);
    return `已删除 ${selectedCount} 项`;
  }
}
