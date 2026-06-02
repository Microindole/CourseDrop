import { courseDropFileStore, localFileIndexRepository } from '../local';
import { CourseDropFileImportService } from './FileImportService';
import { SystemFilePickerService } from './FilePickerService';
import { FileTypeResolver } from './FileTypeResolver';
import { LocalFileImportWorkflow } from './LocalFileImportWorkflow';
import { FileSystemService } from './FileSystemService';

export type { FileImportPlan, FileImportResult, PickedFile } from './FileModels';
export type { FileImportService } from './FileImportService';
export { CourseDropFileImportService } from './FileImportService';
export type { FilePickerService } from './FilePickerService';
export { SystemFilePickerService } from './FilePickerService';
export { FileTypeResolver } from './FileTypeResolver';
export type { CopiedFile, CreatedTextFile, FileMetadata } from './FileSystemService';
export { FileSystemService } from './FileSystemService';
export type { LocalFileImportResult } from './LocalFileImportWorkflow';
export { LocalFileImportWorkflow } from './LocalFileImportWorkflow';

export const fileTypeResolver: FileTypeResolver = new FileTypeResolver();
export const fileSystemService = new FileSystemService();
export const filePickerService = new SystemFilePickerService();
export const fileImportService = new CourseDropFileImportService(
  courseDropFileStore,
  localFileIndexRepository,
  fileSystemService
);
export const localFileImportWorkflow = new LocalFileImportWorkflow(
  filePickerService,
  fileImportService,
  courseDropFileStore,
  fileSystemService,
  localFileIndexRepository
);
