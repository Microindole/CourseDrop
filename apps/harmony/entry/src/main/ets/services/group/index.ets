import { CourseDropGroupCryptoService } from './GroupCryptoService';
import { HttpGroupNetworkContract } from './GroupNetworkContract';
import { apiClient } from '../ApiClient';
import { encryptionService } from '../crypto';
import { filePickerService, fileSystemService } from '../file';
import { courseDropFileStore, localFileIndexRepository } from '../local';
import {
  PreferencesLocalGroupMemberRepository,
  PreferencesLocalGroupMessageRepository,
  PreferencesLocalGroupRepository,
  RuntimeLocalGroupMemberRepository,
  RuntimeLocalGroupMessageRepository,
  RuntimeLocalGroupRepository
} from './GroupRepositories';
import { DefaultGroupFileWorkflow } from './GroupFileWorkflow';
import { DefaultGroupKeyBackupService } from './GroupKeyBackupService';
import { DefaultGroupMessageService } from './GroupMessageService';
import { DefaultGroupRealtimeService } from './GroupRealtimeService';
import { DefaultGroupService } from './GroupService';

export type {
  GroupCryptoService,
  GroupEncryptedPayload,
  GroupMetadataEncryptionResult,
  PlainGroupKeyBackupPayload
} from './GroupCryptoService';
export { CourseDropGroupCryptoService, PendingGroupCryptoService } from './GroupCryptoService';
export type {
  GroupFileDownloadRequest,
  GroupFileDownloadResponse,
  GroupFileUploadRequest,
  GroupFileUploadResponse,
  GroupNetworkContract
} from './GroupNetworkContract';
export type { GroupMembershipResult } from '../../models/Group';
export { HttpGroupNetworkContract, PendingGroupNetworkContract } from './GroupNetworkContract';
export type {
  LocalGroupMemberRepository,
  LocalGroupMessageRepository,
  LocalGroupRepository
} from './GroupRepositories';
export {
  PreferencesLocalGroupMemberRepository,
  PreferencesLocalGroupMessageRepository,
  PreferencesLocalGroupRepository,
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
  BackupGroupKeyCommand,
  GroupKeyBackupService,
  RestoreGroupKeyBackupCommand
} from './GroupKeyBackupService';
export { DefaultGroupKeyBackupService } from './GroupKeyBackupService';
export type {
  GroupMessageService,
  ReceiveGroupFileResult,
  ReceiveGroupFileCommand,
  SendGroupFileMessageCommand,
  SendGroupTextMessageCommand
} from './GroupMessageService';
export { DefaultGroupMessageService } from './GroupMessageService';
export type {
  GroupRealtimeEvent,
  GroupRealtimeListener,
  GroupRealtimeMessage,
  GroupRealtimeService
} from './GroupRealtimeService';
export { DefaultGroupRealtimeService } from './GroupRealtimeService';

export const localGroupRepository = new PreferencesLocalGroupRepository();
export const localGroupMemberRepository = new PreferencesLocalGroupMemberRepository();
export const localGroupMessageRepository = new PreferencesLocalGroupMessageRepository();
export const groupCryptoService = new CourseDropGroupCryptoService();
export const groupNetworkContract = new HttpGroupNetworkContract(apiClient, fileSystemService);
export const groupRealtimeService = new DefaultGroupRealtimeService(apiClient);
export const groupKeyBackupService = new DefaultGroupKeyBackupService(
  localGroupRepository,
  localGroupMemberRepository,
  groupCryptoService,
  groupNetworkContract
);
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
