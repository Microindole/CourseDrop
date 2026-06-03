import { CourseDropGroupCryptoService } from './GroupCryptoService';
import { HttpGroupNetworkContract } from './GroupNetworkContract';
import { apiClient } from '../ApiClient';
import { fileSystemService } from '../file';
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
export { CourseDropGroupCryptoService, PendingGroupCryptoService } from './GroupCryptoService';
export type {
  GroupFileDownloadRequest,
  GroupFileDownloadResponse,
  GroupFileUploadRequest,
  GroupFileUploadResponse,
  GroupNetworkContract
} from './GroupNetworkContract';
export { HttpGroupNetworkContract, PendingGroupNetworkContract } from './GroupNetworkContract';
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
  SendGroupFileMessageCommand,
  SendGroupTextMessageCommand
} from './GroupMessageService';
export { DefaultGroupMessageService } from './GroupMessageService';

export const localGroupRepository = new RuntimeLocalGroupRepository();
export const localGroupMemberRepository = new RuntimeLocalGroupMemberRepository();
export const localGroupMessageRepository = new RuntimeLocalGroupMessageRepository();
export const groupCryptoService = new CourseDropGroupCryptoService();
export const groupNetworkContract = new HttpGroupNetworkContract(apiClient, fileSystemService);
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
