import cryptoFramework from '@ohos.security.cryptoFramework';
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

export class CourseDropGroupCryptoService implements GroupCryptoService {
  async generateGroupKey(): Promise<string> {
    const random = cryptoFramework.createRandom();
    return this.toHex(random.generateRandomSync(32).data);
  }

  async encryptGroupMetadata(plainName: string, groupKeyMaterial: string): Promise<GroupMetadataEncryptionResult> {
    const encrypted = await this.encryptText(plainName, groupKeyMaterial, 'coursedrop:group:metadata:v1');
    return {
      encryptedName: encrypted.ciphertext,
      nameIv: encrypted.iv,
      nameAuthTag: encrypted.authTag
    };
  }

  async decryptGroupMetadata(encryptedName: string, nameIv: string, nameAuthTag: string, groupKeyMaterial: string): Promise<string> {
    return await this.decryptText({
      ciphertext: encryptedName,
      iv: nameIv,
      authTag: nameAuthTag
    }, groupKeyMaterial, 'coursedrop:group:metadata:v1');
  }

  async encryptFilePayload(payload: PlainFilePayload, groupKeyMaterial: string): Promise<GroupEncryptedPayload> {
    return await this.encryptJson(payload, groupKeyMaterial, 'coursedrop:group:payload:v1');
  }

  async decryptFilePayload(payload: GroupEncryptedPayload, groupKeyMaterial: string): Promise<PlainFilePayload> {
    return JSON.parse(await this.decryptText(payload, groupKeyMaterial, 'coursedrop:group:payload:v1')) as PlainFilePayload;
  }

  async encryptTextPayload(payload: PlainTextPayload, groupKeyMaterial: string): Promise<GroupEncryptedPayload> {
    return await this.encryptJson(payload, groupKeyMaterial, 'coursedrop:group:payload:v1');
  }

  async decryptTextPayload(payload: GroupEncryptedPayload, groupKeyMaterial: string): Promise<PlainTextPayload> {
    return JSON.parse(await this.decryptText(payload, groupKeyMaterial, 'coursedrop:group:payload:v1')) as PlainTextPayload;
  }

  async encryptControlPayload(payload: PlainControlPayload, groupKeyMaterial: string): Promise<GroupEncryptedPayload> {
    return await this.encryptJson(payload, groupKeyMaterial, 'coursedrop:group:payload:v1');
  }

  async decryptControlPayload(payload: GroupEncryptedPayload, groupKeyMaterial: string): Promise<PlainControlPayload> {
    return JSON.parse(await this.decryptText(payload, groupKeyMaterial, 'coursedrop:group:payload:v1')) as PlainControlPayload;
  }

  private async encryptJson(payload: Object, groupKeyMaterial: string, aadText: string): Promise<GroupEncryptedPayload> {
    return await this.encryptText(JSON.stringify(payload), groupKeyMaterial, aadText);
  }

  private async encryptText(plainText: string, groupKeyMaterial: string, aadText: string): Promise<GroupEncryptedPayload> {
    const random = cryptoFramework.createRandom();
    const nonce = random.generateRandomSync(12);
    const keyData: cryptoFramework.DataBlob = { data: this.fromHex(groupKeyMaterial) };
    const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const key = await keyGenerator.convertKey(keyData);
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: nonce,
      aad: { data: this.toUtf8(aadText) },
      authTag: { data: new Uint8Array(16) }
    };
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params);
    const plainData = this.toUtf8(plainText);
    const output = await cipher.doFinal({ data: plainData });
    const gcmOutput = this.normalizeGcmEncryptOutput(output.data, params.authTag.data, plainData.byteLength);
    return {
      ciphertext: this.toHex(gcmOutput.ciphertext),
      iv: this.toHex(nonce.data),
      authTag: this.toHex(gcmOutput.authTag)
    };
  }

  private async decryptText(payload: GroupEncryptedPayload, groupKeyMaterial: string, aadText: string): Promise<string> {
    const keyData: cryptoFramework.DataBlob = { data: this.fromHex(groupKeyMaterial) };
    const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const key = await keyGenerator.convertKey(keyData);
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: this.fromHex(payload.iv) },
      aad: { data: this.toUtf8(aadText) },
      authTag: { data: this.fromHex(payload.authTag) }
    };
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
    let output: cryptoFramework.DataBlob;
    try {
      output = await cipher.doFinal({ data: this.fromHex(payload.ciphertext) });
    } catch (error) {
      output = await this.decryptLegacyCombinedGcm(payload, groupKeyMaterial, aadText);
    }
    return this.fromUtf8(output.data);
  }

  private normalizeGcmEncryptOutput(output: Uint8Array, authTag: Uint8Array, plainSizeBytes: number): GroupGcmCipherParts {
    if (output.byteLength >= plainSizeBytes + 16) {
      return {
        ciphertext: output.slice(0, output.byteLength - 16),
        authTag: output.slice(output.byteLength - 16)
      };
    }
    if (this.isAllZero(authTag) && output.byteLength >= 16) {
      return {
        ciphertext: output.slice(0, output.byteLength - 16),
        authTag: output.slice(output.byteLength - 16)
      };
    }
    return {
      ciphertext: output,
      authTag: authTag
    };
  }

  private async decryptLegacyCombinedGcm(
    payload: GroupEncryptedPayload,
    groupKeyMaterial: string,
    aadText: string
  ): Promise<cryptoFramework.DataBlob> {
    const encryptedData = this.fromHex(payload.ciphertext);
    if (encryptedData.byteLength <= 16) {
      throw new Error('密文长度不足');
    }
    const ciphertext = encryptedData.slice(0, encryptedData.byteLength - 16);
    const authTag = encryptedData.slice(encryptedData.byteLength - 16);
    const keyData: cryptoFramework.DataBlob = { data: this.fromHex(groupKeyMaterial) };
    const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const key = await keyGenerator.convertKey(keyData);
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: this.fromHex(payload.iv) },
      aad: { data: this.toUtf8(aadText) },
      authTag: { data: this.isAllZero(this.fromHex(payload.authTag)) ? authTag : this.fromHex(payload.authTag) }
    };
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
    return await cipher.doFinal({ data: ciphertext });
  }

  private isAllZero(data: Uint8Array): boolean {
    for (let index = 0; index < data.byteLength; index += 1) {
      if (data[index] !== 0) {
        return false;
      }
    }
    return data.byteLength > 0;
  }

  private toHex(data: Uint8Array): string {
    let output = '';
    for (let index = 0; index < data.length; index += 1) {
      const next = data[index].toString(16);
      output += next.length === 1 ? `0${next}` : next;
    }
    return output;
  }

  private fromHex(hex: string): Uint8Array {
    const length = Math.floor(hex.length / 2);
    const bytes = new Uint8Array(length);
    for (let index = 0; index < length; index += 1) {
      const offset = index * 2;
      bytes[index] = Number.parseInt(hex.substring(offset, offset + 2), 16);
    }
    return bytes;
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

  private fromUtf8(data: Uint8Array): string {
    let output = '';
    let index = 0;
    while (index < data.length) {
      const first = data[index];
      if (first < 0x80) {
        output += String.fromCharCode(first);
        index += 1;
      } else if (first < 0xe0) {
        const second = data[index + 1];
        output += String.fromCharCode(((first & 0x1f) << 6) | (second & 0x3f));
        index += 2;
      } else {
        const second = data[index + 1];
        const third = data[index + 2];
        output += String.fromCharCode(((first & 0x0f) << 12) | ((second & 0x3f) << 6) | (third & 0x3f));
        index += 3;
      }
    }
    return output;
  }
}

interface GroupGcmCipherParts {
  ciphertext: Uint8Array;
  authTag: Uint8Array;
}
