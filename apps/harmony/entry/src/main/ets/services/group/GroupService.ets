import {
  GroupConfig,
  GroupInvitePayload,
  GroupMember,
  GroupSession
} from '../../models/Group';
import { identityService } from '../identity';
import { GroupCryptoService } from './GroupCryptoService';
import { GroupNetworkContract } from './GroupNetworkContract';
import {
  LocalGroupMemberRepository,
  LocalGroupMessageRepository,
  LocalGroupRepository
} from './GroupRepositories';

export interface CreateGroupCommand {
  plainName: string;
  config: GroupConfig;
}

export interface JoinGroupCommand {
  invite: GroupInvitePayload;
}

export interface GroupService {
  createGroup(command: CreateGroupCommand): Promise<GroupSession>;
  joinGroup(command: JoinGroupCommand): Promise<GroupSession>;
  leaveGroup(groupId: string): Promise<void>;
  syncMembers(groupId: string): Promise<GroupMember[]>;
  updateLocalProfile(groupId: string, avatarText: string, avatarColor: string): GroupSession;
  listLocalGroups(): GroupSession[];
  listMembers(groupId: string): GroupMember[];
}

export class DefaultGroupService implements GroupService {
  private groupRepository: LocalGroupRepository;
  private memberRepository: LocalGroupMemberRepository;
  private messageRepository: LocalGroupMessageRepository;
  private cryptoService: GroupCryptoService;
  private networkContract: GroupNetworkContract;

  constructor(
    groupRepository: LocalGroupRepository,
    memberRepository: LocalGroupMemberRepository,
    messageRepository: LocalGroupMessageRepository,
    cryptoService: GroupCryptoService,
    networkContract: GroupNetworkContract
  ) {
    this.groupRepository = groupRepository;
    this.memberRepository = memberRepository;
    this.messageRepository = messageRepository;
    this.cryptoService = cryptoService;
    this.networkContract = networkContract;
  }

  async createGroup(command: CreateGroupCommand): Promise<GroupSession> {
    const identity = identityService.getLocalIdentity();
    const creatorId = identity === undefined ? '' : identity.fingerprintId;
    const groupKeyMaterial = await this.cryptoService.generateGroupKey();
    const metadata = await this.cryptoService.encryptGroupMetadata(command.plainName, groupKeyMaterial);
    const response = await this.networkContract.createGroup({
      encryptedName: metadata.encryptedName,
      nameIv: metadata.nameIv,
      nameAuthTag: metadata.nameAuthTag,
      creatorId: creatorId,
      configJson: JSON.stringify(command.config)
    });
    const now = new Date().toISOString();
    const session: GroupSession = {
      id: response.id,
      encryptedName: response.encryptedName,
      nameIv: response.nameIv,
      nameAuthTag: response.nameAuthTag,
      plainName: command.plainName,
      creatorId: response.creatorId,
      joinedAt: now,
      status: 'ACTIVE',
      groupKeyMaterial: groupKeyMaterial,
      config: this.parseConfig(response.configJson, command.config),
      syncCursor: ''
    };
    this.groupRepository.save(session);
    this.memberRepository.save({
      groupId: session.id,
      fingerprintId: creatorId,
      role: 'OWNER',
      status: 'ACTIVE',
      joinedAt: now
    });
    return session;
  }

  async joinGroup(command: JoinGroupCommand): Promise<GroupSession> {
    const identity = identityService.getLocalIdentity();
    const fingerprintId = identity === undefined ? '' : identity.fingerprintId;
    const response = await this.networkContract.getGroup(command.invite.groupId);
    const plainName = await this.cryptoService.decryptGroupMetadata(
      response.encryptedName,
      response.nameIv,
      response.nameAuthTag,
      command.invite.groupKeyMaterial
    );
    const joined = await this.networkContract.joinGroup(response.id, fingerprintId);
    const session: GroupSession = {
      id: response.id,
      encryptedName: response.encryptedName,
      nameIv: response.nameIv,
      nameAuthTag: response.nameAuthTag,
      plainName: plainName,
      creatorId: response.creatorId,
      joinedAt: joined.joinedAt,
      status: 'ACTIVE',
      groupKeyMaterial: command.invite.groupKeyMaterial,
      config: this.parseConfig(response.configJson, this.defaultConfig()),
      syncCursor: ''
    };
    this.groupRepository.save(session);
    this.memberRepository.save(joined);
    return session;
  }

  async leaveGroup(groupId: string): Promise<void> {
    const identity = identityService.getLocalIdentity();
    const fingerprintId = identity === undefined ? '' : identity.fingerprintId;
    await this.networkContract.leaveGroup(groupId, fingerprintId);
    this.groupRepository.remove(groupId);
    this.memberRepository.removeByGroup(groupId);
    this.messageRepository.removeByGroup(groupId);
  }

  async syncMembers(groupId: string): Promise<GroupMember[]> {
    const members = await this.networkContract.listMembers(groupId);
    members.forEach((member: GroupMember) => {
      this.memberRepository.save(member);
    });
    return this.memberRepository.listByGroup(groupId);
  }

  updateLocalProfile(groupId: string, avatarText: string, avatarColor: string): GroupSession {
    const group = this.groupRepository.findById(groupId);
    if (group === undefined) {
      throw new Error('群组不存在');
    }
    const updated: GroupSession = {
      id: group.id,
      encryptedName: group.encryptedName,
      nameIv: group.nameIv,
      nameAuthTag: group.nameAuthTag,
      plainName: group.plainName,
      creatorId: group.creatorId,
      joinedAt: group.joinedAt,
      status: group.status,
      groupKeyMaterial: group.groupKeyMaterial,
      config: {
        allowText: group.config.allowText,
        expiryHours: group.config.expiryHours,
        maxFileSizeMb: group.config.maxFileSizeMb,
        avatarText: avatarText.length === 0 ? this.defaultAvatarText(group.plainName) : avatarText.substring(0, 2),
        avatarColor: avatarColor.length === 0 ? '#1466FF' : avatarColor
      },
      lastMessageAt: group.lastMessageAt,
      syncCursor: group.syncCursor
    };
    this.groupRepository.save(updated);
    return updated;
  }

  listLocalGroups(): GroupSession[] {
    return this.groupRepository.list();
  }

  listMembers(groupId: string): GroupMember[] {
    return this.memberRepository.listByGroup(groupId);
  }

  private parseConfig(jsonText: string, fallback: GroupConfig): GroupConfig {
    try {
      return JSON.parse(jsonText) as GroupConfig;
    } catch (_error) {
      return fallback;
    }
  }

  private defaultConfig(): GroupConfig {
    return {
      allowText: false,
      expiryHours: 24,
      maxFileSizeMb: 100,
      avatarText: '群',
      avatarColor: '#1466FF'
    };
  }

  private defaultAvatarText(groupName: string): string {
    const normalized = groupName.trim();
    return normalized.length === 0 ? '群' : normalized.substring(0, 1);
  }
}
