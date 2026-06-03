import {
  GroupMessage,
  PlainFilePayload,
  PlainTextPayload
} from '../../models/Group';
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
  targetDirectory: string;
}

export interface GroupMessageService {
  sendFileMessage(command: SendGroupFileMessageCommand): Promise<GroupMessage>;
  sendTextMessage(command: SendGroupTextMessageCommand): Promise<GroupMessage>;
  receiveGroupFile(command: ReceiveGroupFileCommand): Promise<string>;
  syncGroupMessages(groupId: string): Promise<GroupMessage[]>;
  listLocalMessages(groupId: string): GroupMessage[];
}

export class DefaultGroupMessageService implements GroupMessageService {
  private groupRepository: LocalGroupRepository;
  private messageRepository: LocalGroupMessageRepository;
  private cryptoService: GroupCryptoService;
  private networkContract: GroupNetworkContract;

  constructor(
    groupRepository: LocalGroupRepository,
    messageRepository: LocalGroupMessageRepository,
    cryptoService: GroupCryptoService,
    networkContract: GroupNetworkContract
  ) {
    this.groupRepository = groupRepository;
    this.messageRepository = messageRepository;
    this.cryptoService = cryptoService;
    this.networkContract = networkContract;
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


  async receiveGroupFile(_command: ReceiveGroupFileCommand): Promise<string> {
    throw new Error('群组文件下载与解密流程尚未接入');
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
