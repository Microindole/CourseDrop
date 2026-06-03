import { AppConfig } from '../common/AppConfig';
import {
  GroupMessage,
  GroupSession,
  PlainTextPayload
} from '../models/Group';
import { apiClient } from '../services/ApiClient';
import { groupCryptoService, groupMessageService, groupService } from '../services/group';
import { identityService, LocalIdentity } from '../services/identity';

export class GroupTestViewModel {
  serverUrl: string = AppConfig.DEFAULT_SERVER_URL;
  groupName: string = 'CourseDrop 测试群';
  messageText: string = '这是一条群组密文测试消息';
  lastActionText: string = '群组测试页未接入主流程';
  errorMessage: string = '';
  currentIdentity?: LocalIdentity;
  currentGroup?: GroupSession;
  messages: GroupMessage[] = [];

  setServerUrl(serverUrl: string): void {
    this.serverUrl = serverUrl;
    apiClient.setBaseUrl(serverUrl);
  }

  async registerIdentity(): Promise<void> {
    this.currentIdentity = await identityService.registerCurrentDevice();
    this.lastActionText = `本机身份已注册：${this.currentIdentity.fingerprintId}`;
    this.errorMessage = '';
  }

  async createGroup(): Promise<void> {
    this.ensureIdentity();
    this.currentGroup = await groupService.createGroup({
      plainName: this.groupName,
      config: {
        allowText: true,
        expiryHours: 24,
        maxFileSizeMb: 100
      }
    });
    this.lastActionText = `群组已创建：${this.currentGroup.id}`;
    this.errorMessage = '';
  }

  async sendTextMessage(): Promise<void> {
    const group = this.ensureGroup();
    const payload: PlainTextPayload = {
      text: this.messageText
    };
    await groupMessageService.sendTextMessage({
      groupId: group.id,
      payload: payload
    });
    this.messages = groupMessageService.listLocalMessages(group.id);
    this.lastActionText = '密文消息已发送';
    this.errorMessage = '';
  }

  async syncMessages(): Promise<void> {
    const group = this.ensureGroup();
    await groupMessageService.syncGroupMessages(group.id);
    this.messages = groupMessageService.listLocalMessages(group.id);
    this.lastActionText = `已同步 ${this.messages.length} 条消息`;
    this.errorMessage = '';
  }

  async describeMessages(): Promise<string[]> {
    const group = this.ensureGroup();
    const lines: string[] = [];
    for (let index = 0; index < this.messages.length; index += 1) {
      const message = this.messages[index];
      if (message.type === 'TEXT') {
        const payload = await groupCryptoService.decryptTextPayload({
          ciphertext: message.encryptedPayload,
          iv: message.iv,
          authTag: message.authTag
        }, group.groupKeyMaterial);
        lines.push(`${message.senderId}: ${payload.text}`);
      } else {
        lines.push(`${message.senderId}: ${message.type} ${message.id}`);
      }
    }
    return lines;
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
      throw new Error('请先创建测试群组');
    }
    this.currentGroup = groups[0];
    return this.currentGroup;
  }
}
