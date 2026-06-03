import { PendingGroupCryptoService } from './GroupCryptoService';
import { PendingGroupNetworkContract } from './GroupNetworkContract';
import {
  RuntimeLocalGroupMemberRepository,
  RuntimeLocalGroupMessageRepository,
  RuntimeLocalGroupRepository
} from './GroupRepositories';
import { DefaultGroupMessageService } from './GroupMessageService';
import { DefaultGroupService } from './GroupService';

export type {
  GroupCryptoService,
  GroupEncryptedPayload,
  GroupMetadataEncryptionResult
} from './GroupCryptoService';
export { PendingGroupCryptoService } from './GroupCryptoService';
export type {
  GroupFileDownloadRequest,
  GroupFileDownloadResponse,
  GroupFileUploadRequest,
  GroupFileUploadResponse,
  GroupNetworkContract
} from './GroupNetworkContract';
export { PendingGroupNetworkContract } from './GroupNetworkContract';
export type {
  LocalGroupMemberRepository,
  LocalGroupMessageRepository,
  LocalGroupRepository
} from './GroupRepositories';
export {
  RuntimeLocalGroupMemberRepository,
  RuntimeLocalGroupMessageRepository,
  RuntimeLocalGroupRepository
} from './GroupRepositories';
export type {
  CreateGroupCommand,
  GroupService,
  JoinGroupCommand
} from './GroupService';
export { DefaultGroupService } from './GroupService';
export type {
  GroupMessageService,
  ReceiveGroupFileCommand,
  SendGroupFileMessageCommand
} from './GroupMessageService';
export { DefaultGroupMessageService } from './GroupMessageService';

export const localGroupRepository = new RuntimeLocalGroupRepository();
export const localGroupMemberRepository = new RuntimeLocalGroupMemberRepository();
export const localGroupMessageRepository = new RuntimeLocalGroupMessageRepository();
export const groupCryptoService = new PendingGroupCryptoService();
export const groupNetworkContract = new PendingGroupNetworkContract();
export const groupService = new DefaultGroupService(
  localGroupRepository,
  localGroupMemberRepository,
  localGroupMessageRepository,
  groupCryptoService,
  groupNetworkContract
);
export const groupMessageService = new DefaultGroupMessageService(
  localGroupRepository,
  localGroupMessageRepository,
  groupCryptoService,
  groupNetworkContract
);
