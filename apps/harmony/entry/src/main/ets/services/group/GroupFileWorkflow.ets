import { GroupMessage } from '../../models/Group';
import { LocalFileEntry } from '../../models/LocalFileEntry';
import { EncryptionService } from '../crypto';
import { FilePickerService, FileSystemService, PickedFile } from '../file';
import { CourseDropFileStore } from '../local/CourseDropFileStore';
import { LocalFileIndexRepository } from '../local/LocalFileIndexRepository';
import { GroupNetworkContract } from './GroupNetworkContract';
import { GroupMessageService, ReceiveGroupFileResult } from './GroupMessageService';

export interface GroupFileSendResult {
  success: boolean;
  message: string;
  sentCount: number;
}

export interface GroupFileReceiveResult {
  success: boolean;
  message: string;
  localFileId: string;
  localUri: string;
}

export interface GroupFileWorkflow {
  pickEncryptUploadAndSend(groupId: string, expiryHours: number): Promise<GroupFileSendResult>;
  receiveFileMessage(messageId: string): Promise<GroupFileReceiveResult>;
}

export class DefaultGroupFileWorkflow implements GroupFileWorkflow {
  private filePickerService: FilePickerService;
  private fileSystemService: FileSystemService;
  private fileStore: CourseDropFileStore;
  private encryptionService: EncryptionService;
  private networkContract: GroupNetworkContract;
  private messageService: GroupMessageService;
  private indexRepository: LocalFileIndexRepository;

  constructor(
    filePickerService: FilePickerService,
    fileSystemService: FileSystemService,
    fileStore: CourseDropFileStore,
    encryptionService: EncryptionService,
    networkContract: GroupNetworkContract,
    messageService: GroupMessageService,
    indexRepository: LocalFileIndexRepository
  ) {
    this.filePickerService = filePickerService;
    this.fileSystemService = fileSystemService;
    this.fileStore = fileStore;
    this.encryptionService = encryptionService;
    this.networkContract = networkContract;
    this.messageService = messageService;
    this.indexRepository = indexRepository;
  }

  async pickEncryptUploadAndSend(groupId: string, expiryHours: number): Promise<GroupFileSendResult> {
    try {
      const files = await this.filePickerService.pickFiles('FILE');
      if (files.length === 0) {
        return {
          success: false,
          message: '未选择文件',
          sentCount: 0
        };
      }
      let sentCount = 0;
      for (let index = 0; index < files.length; index += 1) {
        await this.encryptUploadAndSend(groupId, files[index], expiryHours);
        sentCount += 1;
      }
      return {
        success: sentCount > 0,
        message: `已发送 ${sentCount} 个群组文件`,
        sentCount: sentCount
      };
    } catch (error) {
      return {
        success: false,
        message: `发送群组文件失败：${String(error)}`,
        sentCount: 0
      };
    }
  }

  async receiveFileMessage(messageId: string): Promise<GroupFileReceiveResult> {
    try {
      const incomingRoot = this.fileStore.incomingRoot();
      if (incomingRoot.length === 0) {
        throw new Error('应用沙箱目录未初始化');
      }
      const encryptedRoot = this.fileStore.cacheRoot();
      if (encryptedRoot.length === 0) {
        throw new Error('应用缓存目录未初始化');
      }
      const received = await this.messageService.receiveGroupFile({
        messageId: messageId,
        encryptedDirectory: encryptedRoot,
        targetDirectory: incomingRoot
      });
      const localFileId = this.indexReceivedFile(received);
      return {
        success: true,
        message: `已下载并解密：${received.payload.displayName}`,
        localFileId: localFileId,
        localUri: received.localUri
      };
    } catch (error) {
      return {
        success: false,
        message: `接收群组文件失败：${String(error)}`,
        localFileId: '',
        localUri: ''
      };
    }
  }

  private async encryptUploadAndSend(groupId: string, file: PickedFile, expiryHours: number): Promise<GroupMessage> {
    const stagingRoot = this.fileStore.stagingRoot();
    if (stagingRoot.length === 0) {
      throw new Error('应用沙箱目录未初始化');
    }
    const stagedFile = this.fileSystemService.copyToDirectory(file.uri, stagingRoot, file.displayName);
    const encryption = await this.encryptionService.encryptFile({
      sourceUri: stagedFile.uri,
      plainSizeBytes: stagedFile.sizeBytes,
      algorithm: 'AES-256-GCM',
      kdfAlgorithm: 'NONE-RAW-KEY'
    });
    const encryptedStat = this.fileSystemService.stat(encryption.encryptedUri, 'application/octet-stream');
    const uploaded = await this.networkContract.uploadFile({
      groupId: groupId,
      localUri: encryption.encryptedUri,
      displayName: `${file.displayName}.cdenc`,
      contentType: 'application/octet-stream',
      encrypted: true,
      encryptionAlgorithm: encryption.algorithm,
      kdfAlgorithm: encryption.kdfAlgorithm,
      kdfSalt: encryption.kdfSalt,
      nonce: encryption.nonce,
      sha256: encryption.sha256,
      plainSizeBytes: encryption.plainSizeBytes,
      expiryHours: expiryHours
    });
    return await this.messageService.sendFileMessage({
      groupId: groupId,
      payload: {
        fileId: uploaded.fileId,
        displayName: file.displayName,
        type: file.type,
        contentType: file.contentType,
        sizeBytes: encryptedStat.sizeBytes,
        plainSizeBytes: encryption.plainSizeBytes,
        sha256: encryption.sha256,
        encryptionAlgorithm: encryption.algorithm,
        kdfAlgorithm: encryption.kdfAlgorithm,
        kdfSalt: encryption.kdfSalt,
        fileKeyMaterial: encryption.keyMaterial,
        fileNonce: encryption.nonce,
        fileAuthTag: encryption.authTag,
        expiresAt: uploaded.expiresAt
      }
    });
  }

  private indexReceivedFile(received: ReceiveGroupFileResult): string {
    const localFileId = `local-${Date.now()}`;
    const entry: LocalFileEntry = {
      id: localFileId,
      displayName: received.payload.displayName,
      type: received.payload.type,
      contentType: received.payload.contentType,
      sizeBytes: received.sizeBytes,
      localUri: received.localUri,
      lastSharedAt: new Date().toISOString(),
      shareCount: 0,
      remoteCached: false,
      encrypted: false
    };
    this.indexRepository.save(entry);
    return localFileId;
  }
}
