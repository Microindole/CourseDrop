import {
  GroupMember,
  GroupMessage,
  GroupSession
} from '../../models/Group';
import { appPreferencesStore } from '../../common/AppPreferencesStore';

const KEY_GROUPS: string = 'groups.sessions';
const KEY_MEMBERS: string = 'groups.members';
const KEY_MESSAGES: string = 'groups.messages';

export interface LocalGroupRepository {
  list(): GroupSession[];
  findById(groupId: string): GroupSession | undefined;
  save(group: GroupSession): void;
  remove(groupId: string): void;
}

export interface LocalGroupMemberRepository {
  listByGroup(groupId: string): GroupMember[];
  save(member: GroupMember): void;
  removeByGroup(groupId: string): void;
}

export interface LocalGroupMessageRepository {
  listByGroup(groupId: string): GroupMessage[];
  findById(messageId: string): GroupMessage | undefined;
  save(message: GroupMessage): void;
  saveAll(messages: GroupMessage[]): void;
  removeByGroup(groupId: string): void;
}

export class RuntimeLocalGroupRepository implements LocalGroupRepository {
  private groups: GroupSession[] = [];

  list(): GroupSession[] {
    return this.groups.map((group: GroupSession) => this.copyGroup(group));
  }

  findById(groupId: string): GroupSession | undefined {
    const group = this.groups.find((next: GroupSession) => next.id === groupId);
    return group === undefined ? undefined : this.copyGroup(group);
  }

  save(group: GroupSession): void {
    const copy = this.copyGroup(group);
    const index = this.groups.findIndex((next: GroupSession) => next.id === group.id);
    if (index < 0) {
      this.groups.push(copy);
      return;
    }
    this.groups[index] = copy;
  }

  remove(groupId: string): void {
    this.groups = this.groups.filter((group: GroupSession) => group.id !== groupId);
  }

  private copyGroup(group: GroupSession): GroupSession {
    return {
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
        avatarText: group.config.avatarText,
        avatarColor: group.config.avatarColor
      },
      lastMessageAt: group.lastMessageAt,
      syncCursor: group.syncCursor
    };
  }
}

export class PreferencesLocalGroupRepository implements LocalGroupRepository {
  private groups: GroupSession[] = [];
  private loaded: boolean = false;

  list(): GroupSession[] {
    this.ensureLoaded();
    return this.groups.map((group: GroupSession) => this.copyGroup(group));
  }

  findById(groupId: string): GroupSession | undefined {
    this.ensureLoaded();
    const group = this.groups.find((next: GroupSession) => next.id === groupId);
    return group === undefined ? undefined : this.copyGroup(group);
  }

  save(group: GroupSession): void {
    this.ensureLoaded();
    const copy = this.copyGroup(group);
    const index = this.groups.findIndex((next: GroupSession) => next.id === group.id);
    if (index < 0) {
      this.groups.push(copy);
    } else {
      this.groups[index] = copy;
    }
    this.persist();
  }

  remove(groupId: string): void {
    this.ensureLoaded();
    this.groups = this.groups.filter((group: GroupSession) => group.id !== groupId);
    this.persist();
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_GROUPS, '[]');
    try {
      const groups = JSON.parse(jsonText) as GroupSession[];
      this.groups = groups.map((group: GroupSession) => this.copyGroup(group));
    } catch (error) {
      console.error(`[CourseDrop] load groups failed: ${String(error)}`);
      this.groups = [];
    }
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_GROUPS, JSON.stringify(this.groups));
  }

  private copyGroup(group: GroupSession): GroupSession {
    return {
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
        avatarText: group.config.avatarText,
        avatarColor: group.config.avatarColor
      },
      lastMessageAt: group.lastMessageAt,
      syncCursor: group.syncCursor
    };
  }
}

export class RuntimeLocalGroupMemberRepository implements LocalGroupMemberRepository {
  private members: GroupMember[] = [];

  listByGroup(groupId: string): GroupMember[] {
    return this.members
      .filter((member: GroupMember) => member.groupId === groupId)
      .map((member: GroupMember) => this.copyMember(member));
  }

  save(member: GroupMember): void {
    const copy = this.copyMember(member);
    const index = this.members.findIndex((next: GroupMember) => {
      return next.groupId === member.groupId && next.fingerprintId === member.fingerprintId;
    });
    if (index < 0) {
      this.members.push(copy);
      return;
    }
    this.members[index] = copy;
  }

  removeByGroup(groupId: string): void {
    this.members = this.members.filter((member: GroupMember) => member.groupId !== groupId);
  }

  private copyMember(member: GroupMember): GroupMember {
    return {
      groupId: member.groupId,
      fingerprintId: member.fingerprintId,
      role: member.role,
      status: member.status,
      joinedAt: member.joinedAt,
      leftAt: member.leftAt
    };
  }
}

export class PreferencesLocalGroupMemberRepository implements LocalGroupMemberRepository {
  private members: GroupMember[] = [];
  private loaded: boolean = false;

  listByGroup(groupId: string): GroupMember[] {
    this.ensureLoaded();
    return this.members
      .filter((member: GroupMember) => member.groupId === groupId)
      .map((member: GroupMember) => this.copyMember(member));
  }

  save(member: GroupMember): void {
    this.ensureLoaded();
    const copy = this.copyMember(member);
    const index = this.members.findIndex((next: GroupMember) => {
      return next.groupId === member.groupId && next.fingerprintId === member.fingerprintId;
    });
    if (index < 0) {
      this.members.push(copy);
    } else {
      this.members[index] = copy;
    }
    this.persist();
  }

  removeByGroup(groupId: string): void {
    this.ensureLoaded();
    this.members = this.members.filter((member: GroupMember) => member.groupId !== groupId);
    this.persist();
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_MEMBERS, '[]');
    try {
      const members = JSON.parse(jsonText) as GroupMember[];
      this.members = members.map((member: GroupMember) => this.copyMember(member));
    } catch (error) {
      console.error(`[CourseDrop] load group members failed: ${String(error)}`);
      this.members = [];
    }
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_MEMBERS, JSON.stringify(this.members));
  }

  private copyMember(member: GroupMember): GroupMember {
    return {
      groupId: member.groupId,
      fingerprintId: member.fingerprintId,
      role: member.role,
      status: member.status,
      joinedAt: member.joinedAt,
      leftAt: member.leftAt
    };
  }
}

export class RuntimeLocalGroupMessageRepository implements LocalGroupMessageRepository {
  private messages: GroupMessage[] = [];

  listByGroup(groupId: string): GroupMessage[] {
    return this.messages
      .filter((message: GroupMessage) => message.groupId === groupId)
      .sort((left: GroupMessage, right: GroupMessage) => Date.parse(left.createdAt) - Date.parse(right.createdAt))
      .map((message: GroupMessage) => this.copyMessage(message));
  }

  findById(messageId: string): GroupMessage | undefined {
    const message = this.messages.find((next: GroupMessage) => next.id === messageId);
    return message === undefined ? undefined : this.copyMessage(message);
  }

  save(message: GroupMessage): void {
    const copy = this.copyMessage(message);
    const index = this.messages.findIndex((next: GroupMessage) => next.id === message.id);
    if (index < 0) {
      this.messages.push(copy);
      return;
    }
    this.messages[index] = copy;
  }

  saveAll(messages: GroupMessage[]): void {
    messages.forEach((message: GroupMessage) => {
      this.save(message);
    });
  }

  removeByGroup(groupId: string): void {
    this.messages = this.messages.filter((message: GroupMessage) => message.groupId !== groupId);
  }

  private copyMessage(message: GroupMessage): GroupMessage {
    return {
      id: message.id,
      groupId: message.groupId,
      senderId: message.senderId,
      type: message.type,
      createdAt: message.createdAt,
      iv: message.iv,
      authTag: message.authTag,
      encryptedPayload: message.encryptedPayload,
      deliveryStatus: message.deliveryStatus
    };
  }
}

export class PreferencesLocalGroupMessageRepository implements LocalGroupMessageRepository {
  private messages: GroupMessage[] = [];
  private loaded: boolean = false;

  listByGroup(groupId: string): GroupMessage[] {
    this.ensureLoaded();
    return this.messages
      .filter((message: GroupMessage) => message.groupId === groupId)
      .sort((left: GroupMessage, right: GroupMessage) => Date.parse(left.createdAt) - Date.parse(right.createdAt))
      .map((message: GroupMessage) => this.copyMessage(message));
  }

  findById(messageId: string): GroupMessage | undefined {
    this.ensureLoaded();
    const message = this.messages.find((next: GroupMessage) => next.id === messageId);
    return message === undefined ? undefined : this.copyMessage(message);
  }

  save(message: GroupMessage): void {
    this.ensureLoaded();
    const copy = this.copyMessage(message);
    const index = this.messages.findIndex((next: GroupMessage) => next.id === message.id);
    if (index < 0) {
      this.messages.push(copy);
    } else {
      this.messages[index] = copy;
    }
    this.persist();
  }

  saveAll(messages: GroupMessage[]): void {
    this.ensureLoaded();
    messages.forEach((message: GroupMessage) => {
      const copy = this.copyMessage(message);
      const index = this.messages.findIndex((next: GroupMessage) => next.id === copy.id);
      if (index < 0) {
        this.messages.push(copy);
      } else {
        this.messages[index] = copy;
      }
    });
    this.persist();
  }

  removeByGroup(groupId: string): void {
    this.ensureLoaded();
    this.messages = this.messages.filter((message: GroupMessage) => message.groupId !== groupId);
    this.persist();
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_MESSAGES, '[]');
    try {
      const messages = JSON.parse(jsonText) as GroupMessage[];
      this.messages = messages.map((message: GroupMessage) => this.copyMessage(message));
    } catch (error) {
      console.error(`[CourseDrop] load group messages failed: ${String(error)}`);
      this.messages = [];
    }
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_MESSAGES, JSON.stringify(this.messages));
  }

  private copyMessage(message: GroupMessage): GroupMessage {
    return {
      id: message.id,
      groupId: message.groupId,
      senderId: message.senderId,
      type: message.type,
      createdAt: message.createdAt,
      iv: message.iv,
      authTag: message.authTag,
      encryptedPayload: message.encryptedPayload,
      deliveryStatus: message.deliveryStatus
    };
  }
}
