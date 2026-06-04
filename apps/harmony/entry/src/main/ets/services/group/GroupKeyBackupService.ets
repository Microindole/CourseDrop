import cryptoFramework from '@ohos.security.cryptoFramework';
import {
  GroupConfig,
  GroupKeyBackupResponse,
  GroupSession
} from '../../models/Group';
import {
  GroupCryptoService,
  GroupEncryptedPayload,
  PlainGroupKeyBackupPayload
} from './GroupCryptoService';
import { GroupNetworkContract } from './GroupNetworkContract';
import {
  LocalGroupMemberRepository,
  LocalGroupRepository
} from './GroupRepositories';
import { identityService } from '../identity';

export interface BackupGroupKeyCommand {
  group: GroupSession;
  passphrase: string;
  kdfAlgorithm?: string;
}

export interface RestoreGroupKeyBackupCommand {
  backup: GroupKeyBackupResponse;
  passphrase: string;
  joinAfterRestore?: boolean;
}

export interface GroupKeyBackupService {
  backupGroupKey(command: BackupGroupKeyCommand): Promise<GroupKeyBackupResponse>;
  listRemoteBackups(): Promise<GroupKeyBackupResponse[]>;
  decryptRemoteBackup(backup: GroupKeyBackupResponse, passphrase: string): Promise<PlainGroupKeyBackupPayload>;
  restoreRemoteBackup(command: RestoreGroupKeyBackupCommand): Promise<GroupSession>;
}

export class DefaultGroupKeyBackupService implements GroupKeyBackupService {
  private groupRepository: LocalGroupRepository;
  private memberRepository: LocalGroupMemberRepository;
  private cryptoService: GroupCryptoService;
  private networkContract: GroupNetworkContract;

  constructor(
    groupRepository: LocalGroupRepository,
    memberRepository: LocalGroupMemberRepository,
    cryptoService: GroupCryptoService,
    networkContract: GroupNetworkContract
  ) {
    this.groupRepository = groupRepository;
    this.memberRepository = memberRepository;
    this.cryptoService = cryptoService;
    this.networkContract = networkContract;
  }

  async backupGroupKey(command: BackupGroupKeyCommand): Promise<GroupKeyBackupResponse> {
    this.requireAccountIdentity();
    const passphrase = command.passphrase.trim();
    if (passphrase.length < 8) {
      throw new Error('恢复口令至少需要 8 个字符');
    }
    const kdfSalt = this.randomHex(16);
    const backupKeyMaterial = await this.deriveBackupKeyMaterial(passphrase, kdfSalt);
    const payload: PlainGroupKeyBackupPayload = {
      groupId: command.group.id,
      groupKeyMaterial: command.group.groupKeyMaterial,
      plainName: command.group.plainName,
      encryptedName: command.group.encryptedName,
      nameIv: command.group.nameIv,
      nameAuthTag: command.group.nameAuthTag,
      configJson: JSON.stringify(command.group.config),
      backedUpAt: new Date().toISOString()
    };
    const encrypted = await this.cryptoService.encryptKeyBackupPayload(payload, backupKeyMaterial);
    return await this.networkContract.upsertKeyBackup(command.group.id, {
      algorithm: 'AES-256-GCM',
      kdfAlgorithm: command.kdfAlgorithm === undefined ? 'SHA256-PASSPHRASE-V1' : command.kdfAlgorithm,
      kdfSalt: kdfSalt,
      iv: encrypted.iv,
      authTag: encrypted.authTag,
      encryptedPayload: encrypted.ciphertext
    });
  }

  async listRemoteBackups(): Promise<GroupKeyBackupResponse[]> {
    this.requireAccountIdentity();
    return await this.networkContract.listMyKeyBackups();
  }

  async decryptRemoteBackup(backup: GroupKeyBackupResponse, passphrase: string): Promise<PlainGroupKeyBackupPayload> {
    if (backup.kdfSalt === undefined || backup.kdfSalt.length === 0) {
      throw new Error('备份缺少恢复参数');
    }
    const backupKeyMaterial = await this.deriveBackupKeyMaterial(passphrase.trim(), backup.kdfSalt);
    const encrypted: GroupEncryptedPayload = {
      ciphertext: backup.encryptedPayload,
      iv: backup.iv,
      authTag: backup.authTag
    };
    return await this.cryptoService.decryptKeyBackupPayload(encrypted, backupKeyMaterial);
  }

  async restoreRemoteBackup(command: RestoreGroupKeyBackupCommand): Promise<GroupSession> {
    this.requireAccountIdentity();
    const payload = await this.decryptRemoteBackup(command.backup, command.passphrase);
    const response = await this.networkContract.getGroup(payload.groupId);
    if (command.joinAfterRestore !== false) {
      const identity = identityService.getLocalIdentity();
      const fingerprintId = identity === undefined ? '' : identity.fingerprintId;
      const member = await this.networkContract.joinGroup(payload.groupId, fingerprintId);
      this.memberRepository.save(member);
    }
    const restored: GroupSession = {
      id: response.id,
      encryptedName: response.encryptedName,
      nameIv: response.nameIv,
      nameAuthTag: response.nameAuthTag,
      plainName: payload.plainName,
      creatorId: response.creatorId,
      joinedAt: new Date().toISOString(),
      status: 'ACTIVE',
      groupKeyMaterial: payload.groupKeyMaterial,
      config: this.parseConfig(response.configJson, payload.configJson),
      syncCursor: ''
    };
    this.groupRepository.save(restored);
    return restored;
  }

  private requireAccountIdentity(): void {
    const identity = identityService.getLocalIdentity();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    if (identity.accountId.length === 0) {
      throw new Error('请先登录账号后再备份群组密钥');
    }
  }

  private async deriveBackupKeyMaterial(passphrase: string, saltHex: string): Promise<string> {
    const md = cryptoFramework.createMd('SHA256');
    const input: cryptoFramework.DataBlob = {
      data: this.toUtf8(`coursedrop:group:key-backup:v1:${saltHex}:${passphrase}`)
    };
    await md.update(input);
    const digest = await md.digest();
    return this.toHex(digest.data);
  }

  private randomHex(byteLength: number): string {
    const random = cryptoFramework.createRandom();
    return this.toHex(random.generateRandomSync(byteLength).data);
  }

  private toUtf8(text: string): Uint8Array {
    const bytes: number[] = [];
    for (let index = 0; index < text.length; index += 1) {
      const code = text.charCodeAt(index);
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xc0 | (code >> 6));
        bytes.push(0x80 | (code & 0x3f));
      } else {
        bytes.push(0xe0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 0x3f));
        bytes.push(0x80 | (code & 0x3f));
      }
    }
    return new Uint8Array(bytes);
  }

  private toHex(data: Uint8Array): string {
    let output = '';
    for (let index = 0; index < data.length; index += 1) {
      const next = data[index].toString(16);
      output += next.length === 1 ? `0${next}` : next;
    }
    return output;
  }

  private parseConfig(primaryJson: string, fallbackJson: string): GroupConfig {
    try {
      return JSON.parse(primaryJson) as GroupConfig;
    } catch (_primaryError) {
      try {
        return JSON.parse(fallbackJson) as GroupConfig;
      } catch (_fallbackError) {
        return {
          allowText: false,
          expiryHours: 24,
          maxFileSizeMb: 100,
          avatarText: '群',
          avatarColor: '#1466FF'
        };
      }
    }
  }
}
