import { AppConfig } from '../common/AppConfig';
import {
  GroupInvitePayload,
  GroupKeyBackupResponse,
  GroupMember,
  GroupMessage,
  GroupSession,
  PlainFilePayload,
  PlainTextPayload
} from '../models/Group';
import { apiClient } from '../services/ApiClient';
import { clipboardService } from '../services/clipboard';
import { groupCryptoService, groupFileWorkflow, groupKeyBackupService, groupMessageService, groupService } from '../services/group';
import { identityService, LocalIdentity } from '../services/identity';
import { relaySourceService } from '../services/relay';

export interface GroupMessagePreview {
  messageId: string;
  type: string;
  text: string;
  downloadable: boolean;
}

export class GroupTestViewModel {
  serverUrl: string = AppConfig.DEFAULT_SERVER_URL;
  groupName: string = '新的群组';
  messageText: string = '';
  inviteText: string = '';
  lastActionText: string = '选择或创建一个群组';
  errorMessage: string = '';
  lastReceivedFileUri: string = '';
  currentIdentity?: LocalIdentity;
  currentGroup?: GroupSession;
  groups: GroupSession[] = [];
  members: GroupMember[] = [];
  messages: GroupMessage[] = [];

  initializeFromLocalState(): void {
    relaySourceService.applyActiveServer();
    this.serverUrl = apiClient.getBaseUrl();
    this.currentIdentity = identityService.getLocalIdentity();
    this.groups = groupService.listLocalGroups();
    if (this.groups.length > 0) {
      this.selectGroup(this.groups[0].id);
      this.lastActionText = `已载入 ${this.groups.length} 个群组`;
    }
  }

  setServerUrl(serverUrl: string): void {
    this.serverUrl = serverUrl;
    apiClient.setBaseUrl(serverUrl);
  }

  async registerIdentity(): Promise<void> {
    this.currentIdentity = await identityService.registerCurrentDevice();
    this.lastActionText = '已准备好本机加密身份';
    this.errorMessage = '';
  }

  selectGroup(groupId: string): void {
    const group = this.groups.find((next: GroupSession) => next.id === groupId);
    if (group === undefined) {
      throw new Error('群组不存在');
    }
    this.currentGroup = group;
    this.members = groupService.listMembers(group.id);
    this.messages = groupMessageService.listLocalMessages(group.id);
    this.inviteText = this.buildInviteText(group);
  }

  async createGroup(): Promise<void> {
    this.ensureIdentity();
    this.currentGroup = await groupService.createGroup({
      plainName: this.groupName,
      config: {
        allowText: true,
        expiryHours: 24,
        maxFileSizeMb: 100,
        avatarText: this.buildAvatarText(this.groupName),
        avatarColor: this.buildAvatarColor(this.groupName)
      }
    });
    this.groups = groupService.listLocalGroups();
    this.members = groupService.listMembers(this.currentGroup.id);
    this.messages = [];
    this.inviteText = this.buildInviteText(this.currentGroup);
    this.lastActionText = `已创建群组：${this.currentGroup.plainName}`;
    this.errorMessage = '';
  }

  async joinGroupFromInvite(inviteText: string): Promise<void> {
    this.ensureIdentity();
    const invite = this.parseInvite(inviteText);
    if (invite.serverUrl.length > 0) {
      this.setServerUrl(invite.serverUrl);
    }
    this.currentGroup = await groupService.joinGroup({
      invite: invite
    });
    this.groups = groupService.listLocalGroups();
    this.members = groupService.listMembers(this.currentGroup.id);
    this.messages = groupMessageService.listLocalMessages(this.currentGroup.id);
    this.inviteText = this.buildInviteText(this.currentGroup);
    this.lastActionText = `已加入群组：${this.currentGroup.plainName}`;
    this.errorMessage = '';
  }

  async copyCurrentInvite(): Promise<void> {
    const group = this.ensureGroup();
    const invite = this.buildInviteText(group);
    await clipboardService.copyText(invite);
    this.inviteText = invite;
    this.lastActionText = '群组邀请已复制，可发送给好友加入';
    this.errorMessage = '';
  }

  async sendTextMessage(): Promise<void> {
    const group = this.ensureGroup();
    if (this.messageText.trim().length === 0) {
      throw new Error('请输入消息内容');
    }
    const payload: PlainTextPayload = {
      text: this.messageText
    };
    await groupMessageService.sendTextMessage({
      groupId: group.id,
      payload: payload
    });
    this.messages = groupMessageService.listLocalMessages(group.id);
    this.messageText = '';
    this.lastActionText = '消息已加密发送';
    this.errorMessage = '';
  }

  async syncMessages(): Promise<void> {
    const group = this.ensureGroup();
    await groupMessageService.syncGroupMessages(group.id);
    this.messages = groupMessageService.listLocalMessages(group.id);
    this.lastActionText = `已同步 ${this.messages.length} 条消息`;
    this.errorMessage = '';
  }

  async syncMembers(): Promise<void> {
    const group = this.ensureGroup();
    this.members = await groupService.syncMembers(group.id);
    this.lastActionText = `已同步 ${this.activeMemberCount()} 位成员`;
    this.errorMessage = '';
  }

  updateGroupProfile(avatarText: string, avatarColor: string): void {
    const group = this.ensureGroup();
    this.currentGroup = groupService.updateLocalProfile(group.id, avatarText.trim(), avatarColor.trim());
    this.groups = groupService.listLocalGroups();
    this.lastActionText = '群资料已更新';
    this.errorMessage = '';
  }

  async backupCurrentGroup(passphrase: string): Promise<void> {
    const group = this.ensureGroup();
    await groupKeyBackupService.backupGroupKey({
      group: group,
      passphrase: passphrase
    });
    this.lastActionText = '群组恢复口令已加密备份';
    this.errorMessage = '';
  }

  async restoreFirstGroupBackup(passphrase: string): Promise<void> {
    const backups = await groupKeyBackupService.listRemoteBackups();
    if (backups.length === 0) {
      throw new Error('当前账号没有可恢复的群组备份');
    }
    let lastError = '';
    for (let index = 0; index < backups.length; index += 1) {
      const backup: GroupKeyBackupResponse = backups[index];
      try {
        this.currentGroup = await groupKeyBackupService.restoreRemoteBackup({
          backup: backup,
          passphrase: passphrase
        });
        this.groups = groupService.listLocalGroups();
        this.members = groupService.listMembers(this.currentGroup.id);
        this.messages = groupMessageService.listLocalMessages(this.currentGroup.id);
        this.inviteText = this.buildInviteText(this.currentGroup);
        await groupMessageService.syncGroupMessages(this.currentGroup.id);
        this.messages = groupMessageService.listLocalMessages(this.currentGroup.id);
        this.lastActionText = `已恢复群组：${this.currentGroup.plainName}`;
        this.errorMessage = '';
        return;
      } catch (error) {
        lastError = String(error);
      }
    }
    throw new Error(lastError.length === 0 ? '恢复失败，请确认口令' : `恢复失败：${lastError}`);
  }

  async leaveCurrentGroup(): Promise<void> {
    const group = this.ensureGroup();
    await groupService.leaveGroup(group.id);
    this.groups = groupService.listLocalGroups();
    this.currentGroup = undefined;
    this.members = [];
    this.messages = [];
    if (this.groups.length > 0) {
      this.selectGroup(this.groups[0].id);
    }
    this.lastActionText = '已退出群组';
    this.errorMessage = '';
  }

  async handleRealtimeMessage(groupId: string): Promise<void> {
    const group = groupService.listLocalGroups().find((next: GroupSession) => next.id === groupId);
    if (group === undefined) {
      return;
    }
    await groupMessageService.syncGroupMessages(groupId);
    this.groups = groupService.listLocalGroups();
    if (this.currentGroup !== undefined && this.currentGroup.id === groupId) {
      this.currentGroup = this.groups.find((next: GroupSession) => next.id === groupId);
      this.messages = groupMessageService.listLocalMessages(groupId);
      this.members = groupService.listMembers(groupId);
    }
    this.errorMessage = '';
  }

  async sendFileMessage(): Promise<void> {
    const group = this.ensureGroup();
    const result = await groupFileWorkflow.pickEncryptUploadAndSend(group.id, group.config.expiryHours);
    if (!result.success) {
      throw new Error(result.message);
    }
    this.messages = groupMessageService.listLocalMessages(group.id);
    this.lastActionText = result.message;
    this.errorMessage = '';
  }

  async receiveLatestFile(): Promise<void> {
    const fileMessage = this.findLatestFileMessage();
    await this.receiveFileMessage(fileMessage.id);
  }

  async receiveFileMessage(messageId: string): Promise<void> {
    const result = await groupFileWorkflow.receiveFileMessage(messageId);
    if (!result.success) {
      throw new Error(result.message);
    }
    this.lastReceivedFileUri = result.localUri;
    this.lastActionText = result.message;
    this.errorMessage = '';
  }

  async describeMessages(): Promise<string[]> {
    const previews = await this.describeMessagePreviews();
    return previews.map((preview: GroupMessagePreview) => preview.text);
  }

  async describeMessagePreviews(): Promise<GroupMessagePreview[]> {
    const group = this.ensureGroup();
    const previews: GroupMessagePreview[] = [];
    for (let index = 0; index < this.messages.length; index += 1) {
      const message = this.messages[index];
      if (message.type === 'TEXT') {
        const payload = await groupCryptoService.decryptTextPayload({
          ciphertext: message.encryptedPayload,
          iv: message.iv,
          authTag: message.authTag
        }, group.groupKeyMaterial);
        previews.push({
          messageId: message.id,
          type: message.type,
          text: payload.text,
          downloadable: false
        });
      } else if (message.type === 'FILE') {
        const payload: PlainFilePayload = await groupCryptoService.decryptFilePayload({
          ciphertext: message.encryptedPayload,
          iv: message.iv,
          authTag: message.authTag
        }, group.groupKeyMaterial);
        const plainSize = payload.plainSizeBytes === undefined ? payload.sizeBytes : payload.plainSizeBytes;
        previews.push({
          messageId: message.id,
          type: message.type,
          text: `${payload.displayName} · ${this.formatSize(plainSize)}`,
          downloadable: true
        });
      } else {
        previews.push({
          messageId: message.id,
          type: message.type,
          text: '一条群组消息',
          downloadable: false
        });
      }
    }
    return previews;
  }

  private ensureIdentity(): LocalIdentity {
    const identity = identityService.getLocalIdentity();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    this.currentIdentity = identity;
    return identity;
  }

  private ensureGroup(): GroupSession {
    if (this.currentGroup !== undefined) {
      return this.currentGroup;
    }
    const groups = groupService.listLocalGroups();
    if (groups.length === 0) {
      throw new Error('请先创建或加入群组');
    }
    this.currentGroup = groups[0];
    return this.currentGroup;
  }

  private findLatestFileMessage(): GroupMessage {
    const group = this.ensureGroup();
    const messages = groupMessageService.listLocalMessages(group.id);
    for (let index = messages.length - 1; index >= 0; index -= 1) {
      if (messages[index].type === 'FILE') {
        return messages[index];
      }
    }
    throw new Error('暂无可下载的群组文件消息');
  }

  private buildInviteText(group: GroupSession): string {
    const serverUrl = apiClient.getBaseUrl();
    const query = `server=${encodeURIComponent(serverUrl)}&id=${encodeURIComponent(group.id)}&key=${encodeURIComponent(group.groupKeyMaterial)}`;
    return `coursedrop://group?${query}`;
  }

  private activeMemberCount(): number {
    return this.members.filter((member: GroupMember) => member.status === 'ACTIVE').length;
  }

  private formatSize(sizeBytes: number): string {
    if (sizeBytes < 1024) {
      return `${sizeBytes} B`;
    }
    if (sizeBytes < 1024 * 1024) {
      return `${Math.round(sizeBytes / 1024)} KB`;
    }
    const sizeMb = sizeBytes / 1024 / 1024;
    return `${sizeMb.toFixed(1)} MB`;
  }

  private parseInvite(rawText: string): GroupInvitePayload {
    const normalized = rawText.trim();
    if (normalized.length === 0) {
      throw new Error('请输入群组邀请');
    }
    if (normalized.startsWith('{')) {
      return JSON.parse(normalized) as GroupInvitePayload;
    }
    const marker = 'coursedrop://group?';
    if (!normalized.startsWith(marker)) {
      throw new Error('群组邀请格式不正确');
    }
    const parsed = this.parseInviteQuery(normalized.substring(marker.length));
    const groupId = parsed.groupId;
    const groupKeyMaterial = parsed.groupKeyMaterial;
    const serverUrl = parsed.serverUrl;
    if (groupId.length === 0 || groupKeyMaterial.length === 0) {
      throw new Error('群组邀请缺少必要信息');
    }
    return {
      groupId: groupId,
      groupKeyMaterial: groupKeyMaterial,
      serverUrl: serverUrl
    };
  }

  private parseInviteQuery(query: string): GroupInvitePayload {
    let groupId = '';
    let groupKeyMaterial = '';
    let serverUrl = '';
    const entries = query.split('&');
    entries.forEach((entry: string) => {
      const separatorIndex = entry.indexOf('=');
      if (separatorIndex < 0) {
        return;
      }
      const key = decodeURIComponent(entry.substring(0, separatorIndex));
      const value = decodeURIComponent(entry.substring(separatorIndex + 1));
      if (key === 'id') {
        groupId = value;
      } else if (key === 'key') {
        groupKeyMaterial = value;
      } else if (key === 'server') {
        serverUrl = value;
      }
    });
    return {
      groupId: groupId,
      groupKeyMaterial: groupKeyMaterial,
      serverUrl: serverUrl
    };
  }

  private buildAvatarText(groupName: string): string {
    const normalized = groupName.trim();
    if (normalized.length === 0) {
      return '群';
    }
    return normalized.substring(0, 1);
  }

  private buildAvatarColor(groupName: string): string {
    const palette: string[] = ['#1466FF', '#00B8D9', '#10B981', '#F59E0B', '#F04438'];
    let seed = 0;
    for (let index = 0; index < groupName.length; index += 1) {
      seed += groupName.charCodeAt(index);
    }
    return palette[seed % palette.length];
  }
}
