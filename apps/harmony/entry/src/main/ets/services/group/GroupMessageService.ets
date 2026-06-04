import {
  GroupMessage,
  PlainFilePayload,
  PlainTextPayload
} from '../../models/Group';
import { EncryptionService } from '../crypto';
import { identityService } from '../identity';
import { GroupCryptoService } from './GroupCryptoService';
import { GroupNetworkContract } from './GroupNetworkContract';
import {
  LocalGroupMessageRepository,
  LocalGroupRepository
} from './GroupRepositories';

export interface SendGroupFileMessageCommand {
  groupId: string;
  payload: PlainFilePayload;
}

export interface SendGroupTextMessageCommand {
  groupId: string;
  payload: PlainTextPayload;
}

export interface ReceiveGroupFileCommand {
  messageId: string;
  encryptedDirectory: string;
  targetDirectory: string;
}

export interface ReceiveGroupFileResult {
  localUri: string;
  sizeBytes: number;
  payload: PlainFilePayload;
}

export interface GroupMessageService {
  sendFileMessage(command: SendGroupFileMessageCommand): Promise<GroupMessage>;
  sendTextMessage(command: SendGroupTextMessageCommand): Promise<GroupMessage>;
  receiveGroupFile(command: ReceiveGroupFileCommand): Promise<ReceiveGroupFileResult>;
  syncGroupMessages(groupId: string): Promise<GroupMessage[]>;
  listLocalMessages(groupId: string): GroupMessage[];
}

export class DefaultGroupMessageService implements GroupMessageService {
  private groupRepository: LocalGroupRepository;
  private messageRepository: LocalGroupMessageRepository;
  private cryptoService: GroupCryptoService;
  private networkContract: GroupNetworkContract;
  private encryptionService: EncryptionService;

  constructor(
    groupRepository: LocalGroupRepository,
    messageRepository: LocalGroupMessageRepository,
    cryptoService: GroupCryptoService,
    networkContract: GroupNetworkContract,
    encryptionService: EncryptionService
  ) {
    this.groupRepository = groupRepository;
    this.messageRepository = messageRepository;
    this.cryptoService = cryptoService;
    this.networkContract = networkContract;
    this.encryptionService = encryptionService;
  }

  async sendFileMessage(command: SendGroupFileMessageCommand): Promise<GroupMessage> {
    const group = this.groupRepository.findById(command.groupId);
    if (group === undefined) {
      throw new Error('群组不存在');
    }
    const identity = identityService.getLocalIdentity();
    const senderId = identity === undefined ? '' : identity.fingerprintId;
    const encrypted = await this.cryptoService.encryptFilePayload(command.payload, group.groupKeyMaterial);
    const message: GroupMessage = {
      id: `group-message-${Date.now()}-${Math.floor(Math.random() * 100000)}`,
      groupId: command.groupId,
      senderId: senderId,
      type: 'FILE',
      createdAt: new Date().toISOString(),
      iv: encrypted.iv,
      authTag: encrypted.authTag,
      encryptedPayload: encrypted.ciphertext,
      deliveryStatus: 'LOCAL_ONLY'
    };
    this.messageRepository.save(message);
    const synced = await this.networkContract.sendMessage(command.groupId, message);
    this.messageRepository.save({
      id: synced.id,
      groupId: synced.groupId,
      senderId: synced.senderId,
      type: synced.type,
      createdAt: synced.createdAt,
      iv: synced.iv,
      authTag: synced.authTag,
      encryptedPayload: synced.encryptedPayload,
      deliveryStatus: 'SYNCED'
    });
    return synced;
  }

  async sendTextMessage(command: SendGroupTextMessageCommand): Promise<GroupMessage> {
    const group = this.groupRepository.findById(command.groupId);
    if (group === undefined) {
      throw new Error('群组不存在');
    }
    const identity = identityService.getLocalIdentity();
    const senderId = identity === undefined ? '' : identity.fingerprintId;
    const encrypted = await this.cryptoService.encryptTextPayload(command.payload, group.groupKeyMaterial);
    const message: GroupMessage = {
      id: `group-message-${Date.now()}-${Math.floor(Math.random() * 100000)}`,
      groupId: command.groupId,
      senderId: senderId,
      type: 'TEXT',
      createdAt: new Date().toISOString(),
      iv: encrypted.iv,
      authTag: encrypted.authTag,
      encryptedPayload: encrypted.ciphertext,
      deliveryStatus: 'LOCAL_ONLY'
    };
    this.messageRepository.save(message);
    const synced = await this.networkContract.sendMessage(command.groupId, message);
    this.messageRepository.save({
      id: synced.id,
      groupId: synced.groupId,
      senderId: synced.senderId,
      type: synced.type,
      createdAt: synced.createdAt,
      iv: synced.iv,
      authTag: synced.authTag,
      encryptedPayload: synced.encryptedPayload,
      deliveryStatus: 'SYNCED'
    });
    return synced;
  }


  async receiveGroupFile(command: ReceiveGroupFileCommand): Promise<ReceiveGroupFileResult> {
    const message = this.messageRepository.findById(command.messageId);
    if (message === undefined) {
      throw new Error('群组文件消息不存在');
    }
    if (message.type !== 'FILE') {
      throw new Error('该消息不是文件消息');
    }
    const group = this.groupRepository.findById(message.groupId);
    if (group === undefined) {
      throw new Error('群组不存在');
    }
    const payload = await this.cryptoService.decryptFilePayload({
      ciphertext: message.encryptedPayload,
      iv: message.iv,
      authTag: message.authTag
    }, group.groupKeyMaterial);
    const downloaded = await this.networkContract.downloadFile({
      groupId: message.groupId,
      fileId: payload.fileId,
      targetDirectory: command.encryptedDirectory
    });
    const decrypted = await this.encryptionService.decryptFile({
      encryptedUri: downloaded.localUri,
      targetDirectory: command.targetDirectory,
      algorithm: payload.encryptionAlgorithm,
      kdfAlgorithm: payload.kdfAlgorithm,
      kdfSalt: payload.kdfSalt,
      nonce: payload.fileNonce,
      keyMaterial: payload.fileKeyMaterial,
      authTag: payload.fileAuthTag
    });
    return {
      localUri: decrypted.plainUri,
      sizeBytes: decrypted.plainSizeBytes,
      payload: payload
    };
  }

  async syncGroupMessages(groupId: string): Promise<GroupMessage[]> {
    const group = this.groupRepository.findById(groupId);
    if (group === undefined) {
      throw new Error('群组不存在');
    }
    const result = await this.networkContract.syncMessages(groupId, group.syncCursor === undefined ? '' : group.syncCursor);
    const messages = result.messages.map((message: GroupMessage) => {
      return {
        id: message.id,
        groupId: message.groupId,
        senderId: message.senderId,
        type: message.type,
        createdAt: message.createdAt,
        iv: message.iv,
        authTag: message.authTag,
        encryptedPayload: message.encryptedPayload,
        deliveryStatus: 'SYNCED'
      } as GroupMessage;
    });
    this.messageRepository.saveAll(messages);
    this.groupRepository.save({
      id: group.id,
      encryptedName: group.encryptedName,
      nameIv: group.nameIv,
      nameAuthTag: group.nameAuthTag,
      plainName: group.plainName,
      creatorId: group.creatorId,
      joinedAt: group.joinedAt,
      status: group.status,
      groupKeyMaterial: group.groupKeyMaterial,
      config: group.config,
      lastMessageAt: messages.length === 0 ? group.lastMessageAt : messages[messages.length - 1].createdAt,
      syncCursor: result.nextCursor
    });
    return messages;
  }

  listLocalMessages(groupId: string): GroupMessage[] {
    return this.messageRepository.listByGroup(groupId);
  }
}
