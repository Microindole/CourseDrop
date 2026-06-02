import { LocalShareService } from './LocalShareService';
import { apiClient } from '../ApiClient';
import { PreferencesShareSessionRepository } from './ShareSessionRepository';
import { RelayShareApi } from './RelayShareApi';
import { transferTaskRepository } from '../transfer';
import { localFileIndexRepository } from '../local';
import { courseDropFileStore } from '../local';
import { fileSystemService } from '../file';
import { fileImportService, filePickerService } from '../file';
import { ShareService } from './ShareService';
import { DefaultShareDraftWorkflow } from './ShareDraftWorkflow';
import { ShareQrImageService } from './ShareQrImageService';

export type { ShareOperationResult, ShareService, TransferStats } from './ShareService';
export { LocalShareService } from './LocalShareService';
export type { ShareSessionRepository } from './ShareSessionRepository';
export { LocalShareSessionRepository, PreferencesShareSessionRepository } from './ShareSessionRepository';
export type { CreateRelayShareResponse, RelayShareDownloadResponse, RelayShareItemResponse } from './RelayShareApi';
export { RelayShareApi } from './RelayShareApi';
export type { TransferTaskRepository } from './TransferTaskRepository';
export { LocalTransferTaskRepository } from './TransferTaskRepository';
export type { ShareDraftWorkflow } from './ShareDraftWorkflow';
export { DefaultShareDraftWorkflow } from './ShareDraftWorkflow';
export { ShareQrImageService } from './ShareQrImageService';

export const shareService: ShareService = new LocalShareService(
  new PreferencesShareSessionRepository(),
  transferTaskRepository,
  new RelayShareApi(apiClient),
  localFileIndexRepository
);
export const shareDraftWorkflow = new DefaultShareDraftWorkflow(
  filePickerService,
  fileImportService,
  shareService
);
export const shareQrImageService = new ShareQrImageService(
  apiClient,
  courseDropFileStore,
  fileSystemService
);
