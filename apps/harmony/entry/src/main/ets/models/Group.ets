import { TransferItemType } from './CommonTypes';

export type GroupStatus = 'ACTIVE' | 'ARCHIVED' | 'DISBANDED';
export type GroupMemberRole = 'OWNER' | 'MEMBER';
export type GroupMemberStatus = 'ACTIVE' | 'LEFT' | 'REMOVED';
export type GroupMessageType = 'FILE' | 'TEXT' | 'CONTROL';
export type GroupControlAction = 'MEMBER_JOIN' | 'MEMBER_LEAVE' | 'KEY_ROTATION';
export type GroupMessageDeliveryStatus = 'LOCAL_ONLY' | 'SYNCED' | 'FAILED';

export interface GroupConfig {
  allowText: boolean;
  expiryHours: number;
  maxFileSizeMb: number;
  avatarText?: string;
  avatarColor?: string;
}

export interface GroupSession {
  id: string;
  encryptedName: string;
  nameIv: string;
  nameAuthTag: string;
  plainName: string;
  creatorId: string;
  joinedAt: string;
  status: GroupStatus;
  groupKeyMaterial: string;
  config: GroupConfig;
  lastMessageAt?: string;
  syncCursor?: string;
}

export interface GroupMember {
  groupId: string;
  fingerprintId: string;
  role: GroupMemberRole;
  status: GroupMemberStatus;
  joinedAt: string;
  leftAt?: string;
}

export interface GroupMessage {
  id: string;
  groupId: string;
  senderId: string;
  type: GroupMessageType;
  createdAt: string;
  iv: string;
  authTag: string;
  encryptedPayload: string;
  deliveryStatus?: GroupMessageDeliveryStatus;
}

export interface PlainTextPayload {
  text: string;
}

export interface PlainControlPayload {
  action: GroupControlAction;
  targetMemberId?: string;
  extraData?: string;
}

export interface PlainFilePayload {
  fileId: string;
  displayName: string;
  type: TransferItemType;
  contentType: string;
  sizeBytes: number;
  plainSizeBytes?: number;
  sha256: string;
  encryptionAlgorithm: string;
  kdfAlgorithm: string;
  kdfSalt: string;
  fileKeyMaterial: string;
  fileNonce: string;
  fileAuthTag: string;
  expiresAt: string;
}

export interface GroupInvitePayload {
  groupId: string;
  groupKeyMaterial: string;
  serverUrl: string;
}

export interface GroupMessageCursor {
  groupId: string;
  cursor: string;
}

export interface GroupCreateRequest {
  encryptedName: string;
  nameIv: string;
  nameAuthTag: string;
  creatorId: string;
  configJson: string;
}

export interface GroupCreateResponse {
  id: string;
  encryptedName: string;
  nameIv: string;
  nameAuthTag: string;
  creatorId: string;
  createdAt: string;
  configJson: string;
}

export interface GroupMessageSyncResult {
  messages: GroupMessage[];
  nextCursor: string;
}

export interface GroupMembershipResult {
  group: GroupCreateResponse;
  member: GroupMember;
}

export interface GroupKeyBackupRequest {
  algorithm: string;
  kdfAlgorithm: string;
  kdfSalt?: string;
  iv: string;
  authTag: string;
  encryptedPayload: string;
}

export interface GroupKeyBackupResponse {
  id: string;
  accountId: string;
  fingerprintId: string;
  groupId: string;
  algorithm: string;
  kdfAlgorithm: string;
  kdfSalt?: string;
  iv: string;
  authTag: string;
  encryptedPayload: string;
  createdAt: string;
  updatedAt: string;
}
