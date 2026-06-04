import { CourseDropGroupCryptoService } from './GroupCryptoService';
import { HttpGroupNetworkContract } from './GroupNetworkContract';
import { apiClient } from '../ApiClient';
import { encryptionService } from '../crypto';
import { filePickerService, fileSystemService } from '../file';
import { courseDropFileStore, localFileIndexRepository } from '../local';
import {
  RuntimeLocalGroupMemberRepository,
  RuntimeLocalGroupMessageRepository,
  RuntimeLocalGroupRepository
} from './GroupRepositories';
import { DefaultGroupFileWorkflow } from './GroupFileWorkflow';
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
  GroupFileReceiveResult,
  GroupFileSendResult,
  GroupFileWorkflow
} from './GroupFileWorkflow';
export { DefaultGroupFileWorkflow } from './GroupFileWorkflow';
export type {
  GroupMessageService,
  ReceiveGroupFileResult,
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
  groupNetworkContract,
  encryptionService
);
export const groupFileWorkflow = new DefaultGroupFileWorkflow(
  filePickerService,
  fileSystemService,
  courseDropFileStore,
  encryptionService,
  groupNetworkContract,
  groupMessageService,
  localFileIndexRepository
);
