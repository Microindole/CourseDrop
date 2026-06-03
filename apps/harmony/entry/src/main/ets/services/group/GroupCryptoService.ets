import {
  PlainControlPayload,
  PlainFilePayload,
  PlainTextPayload
} from '../../models/Group';

export interface GroupEncryptedPayload {
  ciphertext: string;
  iv: string;
  authTag: string;
}

export interface GroupMetadataEncryptionResult {
  encryptedName: string;
  nameIv: string;
  nameAuthTag: string;
}

export interface GroupCryptoService {
  generateGroupKey(): Promise<string>;
  encryptGroupMetadata(plainName: string, groupKeyMaterial: string): Promise<GroupMetadataEncryptionResult>;
  decryptGroupMetadata(encryptedName: string, nameIv: string, nameAuthTag: string, groupKeyMaterial: string): Promise<string>;
  encryptFilePayload(payload: PlainFilePayload, groupKeyMaterial: string): Promise<GroupEncryptedPayload>;
  decryptFilePayload(payload: GroupEncryptedPayload, groupKeyMaterial: string): Promise<PlainFilePayload>;
  encryptTextPayload(payload: PlainTextPayload, groupKeyMaterial: string): Promise<GroupEncryptedPayload>;
  decryptTextPayload(payload: GroupEncryptedPayload, groupKeyMaterial: string): Promise<PlainTextPayload>;
  encryptControlPayload(payload: PlainControlPayload, groupKeyMaterial: string): Promise<GroupEncryptedPayload>;
  decryptControlPayload(payload: GroupEncryptedPayload, groupKeyMaterial: string): Promise<PlainControlPayload>;
}

export class PendingGroupCryptoService implements GroupCryptoService {
  async generateGroupKey(): Promise<string> {
    return this.randomHex(32);
  }

  async encryptGroupMetadata(_plainName: string, _groupKeyMaterial: string): Promise<GroupMetadataEncryptionResult> {
    throw new Error('群组加密服务尚未接入');
  }

  async decryptGroupMetadata(_encryptedName: string, _nameIv: string, _nameAuthTag: string, _groupKeyMaterial: string): Promise<string> {
    throw new Error('群组加密服务尚未接入');
  }

  async encryptFilePayload(_payload: PlainFilePayload, _groupKeyMaterial: string): Promise<GroupEncryptedPayload> {
    throw new Error('群组加密服务尚未接入');
  }

  async decryptFilePayload(_payload: GroupEncryptedPayload, _groupKeyMaterial: string): Promise<PlainFilePayload> {
    throw new Error('群组加密服务尚未接入');
  }

  async encryptTextPayload(_payload: PlainTextPayload, _groupKeyMaterial: string): Promise<GroupEncryptedPayload> {
    throw new Error('群组加密服务尚未接入');
  }

  async decryptTextPayload(_payload: GroupEncryptedPayload, _groupKeyMaterial: string): Promise<PlainTextPayload> {
    throw new Error('群组加密服务尚未接入');
  }

  async encryptControlPayload(_payload: PlainControlPayload, _groupKeyMaterial: string): Promise<GroupEncryptedPayload> {
    throw new Error('群组加密服务尚未接入');
  }

  async decryptControlPayload(_payload: GroupEncryptedPayload, _groupKeyMaterial: string): Promise<PlainControlPayload> {
    throw new Error('群组加密服务尚未接入');
  }

  private randomHex(byteLength: number): string {
    let output = '';
    for (let index = 0; index < byteLength; index += 1) {
      const next = Math.floor(Math.random() * 256).toString(16);
      output += next.length === 1 ? `0${next}` : next;
    }
    return output;
  }
}
