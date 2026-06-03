import {
  GroupCreateRequest,
  GroupCreateResponse,
  GroupMember,
  GroupMessage,
  GroupMessageSyncResult
} from '../../models/Group';

export interface GroupFileUploadRequest {
  groupId: string;
  localUri: string;
  displayName: string;
  contentType: string;
  encrypted: boolean;
  encryptionAlgorithm: string;
  kdfAlgorithm: string;
  kdfSalt: string;
  nonce: string;
  sha256: string;
  plainSizeBytes: number;
}

export interface GroupFileUploadResponse {
  fileId: string;
  groupId: string;
  sizeBytes: number;
  expiresAt: string;
}

export interface GroupFileDownloadRequest {
  groupId: string;
  fileId: string;
  targetDirectory: string;
}

export interface GroupFileDownloadResponse {
  localUri: string;
  sizeBytes: number;
}

export interface GroupNetworkContract {
  createGroup(request: GroupCreateRequest): Promise<GroupCreateResponse>;
  getGroup(groupId: string): Promise<GroupCreateResponse>;
  joinGroup(groupId: string, fingerprintId: string): Promise<GroupMember>;
  leaveGroup(groupId: string, fingerprintId: string): Promise<void>;
  sendMessage(groupId: string, message: GroupMessage): Promise<GroupMessage>;
  syncMessages(groupId: string, cursor: string): Promise<GroupMessageSyncResult>;
  uploadFile(request: GroupFileUploadRequest): Promise<GroupFileUploadResponse>;
  downloadFile(request: GroupFileDownloadRequest): Promise<GroupFileDownloadResponse>;
}

export class PendingGroupNetworkContract implements GroupNetworkContract {
  async createGroup(_request: GroupCreateRequest): Promise<GroupCreateResponse> {
    throw new Error('群组服务端接口尚未接入');
  }

  async getGroup(_groupId: string): Promise<GroupCreateResponse> {
    throw new Error('群组服务端接口尚未接入');
  }

  async joinGroup(_groupId: string, _fingerprintId: string): Promise<GroupMember> {
    throw new Error('群组服务端接口尚未接入');
  }

  async leaveGroup(_groupId: string, _fingerprintId: string): Promise<void> {
    throw new Error('群组服务端接口尚未接入');
  }

  async sendMessage(_groupId: string, _message: GroupMessage): Promise<GroupMessage> {
    throw new Error('群组服务端接口尚未接入');
  }

  async syncMessages(_groupId: string, _cursor: string): Promise<GroupMessageSyncResult> {
    throw new Error('群组服务端接口尚未接入');
  }

  async uploadFile(_request: GroupFileUploadRequest): Promise<GroupFileUploadResponse> {
    throw new Error('群组服务端接口尚未接入');
  }

  async downloadFile(_request: GroupFileDownloadRequest): Promise<GroupFileDownloadResponse> {
    throw new Error('群组服务端接口尚未接入');
  }
}
