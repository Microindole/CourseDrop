import { LocalFileEntry } from '../../models/LocalFileEntry';
import { TransferTask } from '../../models/TransferTask';
import { LocalFileIndexRepository } from '../local/LocalFileIndexRepository';
import { CourseDropFileStore } from '../local/CourseDropFileStore';
import { RelayTransferApi } from './RelayTransferApi';
import { TransferTaskService } from './TransferTaskService';
import { FileTypeResolver } from '../file/FileTypeResolver';
import { encryptionService } from '../crypto';

export interface UploadLocalFileCommand {
  shareId: string;
  localFileId: string;
  encrypted: boolean;
  onUploaded?: (
    remoteItemId: string,
    remoteUrl: string,
    expiresAt: string,
    e2eeKeyMaterial: string,
    e2eeNonce: string,
    e2eeAuthTag: string
  ) => void;
}

export interface DownloadShareItemCommand {
  code: string;
  itemId: string;
  fingerprintId?: string;
  accountId?: string;
  e2eeKeyMaterial?: string;
  e2eeNonce?: string;
  e2eeAuthTag?: string;
}

export interface TransferService {
  uploadLocalFile(command: UploadLocalFileCommand): Promise<TransferTask>;
  downloadShareItem(command: DownloadShareItemCommand): Promise<TransferTask>;
  listTasks(): TransferTask[];
  listSessionTasks(sessionId: string): TransferTask[];
}

export class DefaultTransferService implements TransferService {
  private taskService: TransferTaskService;
  private transferApi: RelayTransferApi;
  private fileIndexRepository: LocalFileIndexRepository;
  private fileStore: CourseDropFileStore;
  private fileTypeResolver: FileTypeResolver = new FileTypeResolver();

  constructor(
    taskService: TransferTaskService,
    transferApi: RelayTransferApi,
    fileIndexRepository: LocalFileIndexRepository,
    fileStore: CourseDropFileStore
  ) {
    this.taskService = taskService;
    this.transferApi = transferApi;
    this.fileIndexRepository = fileIndexRepository;
    this.fileStore = fileStore;
  }

  async uploadLocalFile(command: UploadLocalFileCommand): Promise<TransferTask> {
    const task = this.taskService.createTask(command.localFileId, 'UPLOAD', 'RELAY', command.shareId);
    this.taskService.start(task.id);
    let uploadPath = '';
    try {
      const file = this.requireLocalFile(command.localFileId);
      let localUri = file.localUri;
      uploadPath = localUri;
      let encrypted = false;
      let encryptionAlgorithm = '';
      let kdfAlgorithm = '';
      let kdfSalt = '';
      let nonce = '';
      let e2eeKeyMaterial = '';
      let e2eeNonce = '';
      let e2eeAuthTag = '';
      let sha256 = '';
      let plainSizeBytes = file.sizeBytes;
      const shouldEncrypt = command.encrypted && file.contentType !== 'text/plain' && file.type !== 'TEXT';
      if (shouldEncrypt) {
        const result = await encryptionService.encryptFile({
          sourceUri: file.localUri,
          plainSizeBytes: file.sizeBytes,
          algorithm: 'AES-256-GCM',
          kdfAlgorithm: 'NONE-RAW-KEY'
        });
        localUri = result.encryptedUri;
        uploadPath = localUri;
        encrypted = true;
        encryptionAlgorithm = result.algorithm;
        kdfAlgorithm = result.kdfAlgorithm;
        kdfSalt = result.kdfSalt;
        nonce = result.authTag.length > 0 ? `${result.nonce}.${result.authTag}` : result.nonce;
        e2eeKeyMaterial = result.keyMaterial;
        e2eeNonce = result.nonce;
        e2eeAuthTag = result.authTag;
        sha256 = result.sha256;
        plainSizeBytes = result.plainSizeBytes;
      }
      const response = await this.transferApi.uploadShareItem({
        shareId: command.shareId,
        localUri: localUri,
        displayName: file.displayName,
        contentType: file.contentType,
        encrypted: encrypted,
        encryptionAlgorithm: encryptionAlgorithm.length > 0 ? encryptionAlgorithm : undefined,
        kdfAlgorithm: kdfAlgorithm.length > 0 ? kdfAlgorithm : undefined,
        kdfSalt: kdfSalt.length > 0 ? kdfSalt : undefined,
        nonce: nonce.length > 0 ? nonce : undefined,
        sha256: sha256.length > 0 ? sha256 : undefined,
        plainSizeBytes: plainSizeBytes
      });
      if (command.onUploaded !== undefined) {
        command.onUploaded(response.id, '', response.expiresAt === undefined ? '' : response.expiresAt, e2eeKeyMaterial, e2eeNonce, e2eeAuthTag);
      }
      file.remoteCached = true;
      file.shareCount = file.shareCount + 1;
      file.lastSharedAt = new Date().toISOString();
      this.fileIndexRepository.save(file);
      return this.taskService.complete(task.id);
    } catch (error) {
      const detail = uploadPath.length > 0 ? `${String(error)} · ${uploadPath}` : String(error);
      return this.taskService.fail(task.id, detail);
    }
  }

  async downloadShareItem(command: DownloadShareItemCommand): Promise<TransferTask> {
    const task = this.taskService.createTask(command.itemId, 'DOWNLOAD', 'RELAY');
    this.taskService.start(task.id);
    try {
      const result = await this.transferApi.downloadShareItem({
        code: command.code,
        itemId: command.itemId,
        targetDirectory: this.fileStore.incomingRoot(),
        fingerprintId: command.fingerprintId,
        accountId: command.accountId
      });
      let localUri = result.localUri;
      let sizeBytes = result.sizeBytes;
      let encrypted = false;
      if (
        command.e2eeKeyMaterial !== undefined &&
        command.e2eeKeyMaterial.length > 0 &&
        command.e2eeNonce !== undefined &&
        command.e2eeNonce.length > 0 &&
        command.e2eeAuthTag !== undefined &&
        command.e2eeAuthTag.length > 0
      ) {
        const decrypted = await encryptionService.decryptFile({
          encryptedUri: result.localUri,
          targetDirectory: this.fileStore.incomingRoot(),
          algorithm: 'AES-256-GCM',
          kdfAlgorithm: 'NONE-RAW-KEY',
          kdfSalt: '',
          nonce: command.e2eeNonce,
          keyMaterial: command.e2eeKeyMaterial,
          authTag: command.e2eeAuthTag
        });
        localUri = decrypted.plainUri;
        sizeBytes = decrypted.plainSizeBytes;
        encrypted = true;
      }
      this.fileIndexRepository.save({
        id: `download-${Date.now()}`,
        displayName: result.displayName,
        type: this.fileTypeResolver.resolve(result.contentType, result.displayName),
        contentType: result.contentType,
        sizeBytes: sizeBytes,
        localUri: localUri,
        shareCount: 0,
        remoteCached: false,
        encrypted: encrypted
      });
      return this.taskService.complete(task.id);
    } catch (error) {
      return this.taskService.fail(task.id, String(error));
    }
  }

  listTasks(): TransferTask[] {
    return this.taskService.listAll();
  }

  listSessionTasks(sessionId: string): TransferTask[] {
    return this.taskService.listBySession(sessionId);
  }

  private requireLocalFile(localFileId: string): LocalFileEntry {
    const file = this.fileIndexRepository.findById(localFileId);
    if (file === undefined) {
      throw new Error(`本地文件不存在：${localFileId}`);
    }
    return file;
  }
}
