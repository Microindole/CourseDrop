import cryptoFramework from '@ohos.security.cryptoFramework';
import { fileIo } from '@kit.CoreFileKit';
import { DecryptionPlan, DecryptionResult, EncryptionPlan, EncryptionResult } from './CryptoModels';

export interface EncryptionService {
  encryptFile(plan: EncryptionPlan): Promise<EncryptionResult>;
  decryptFile(plan: DecryptionPlan): Promise<DecryptionResult>;
}

export class CourseDropEncryptionService implements EncryptionService {
  async encryptFile(plan: EncryptionPlan): Promise<EncryptionResult> {
    try {
      const plainData = this.readFile(plan.sourceUri);
      const random = cryptoFramework.createRandom();
      const nonce = random.generateRandomSync(12);
      const aad = this.toBytes('coursedrop:file:v1');
      const authTag: cryptoFramework.DataBlob = { data: new Uint8Array(16) };
      const aadBlob: cryptoFramework.DataBlob = { data: aad };
      const params: cryptoFramework.GcmParamsSpec = {
        algName: 'GcmParamsSpec',
        iv: nonce,
        aad: aadBlob,
        authTag: authTag
      };
      const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const key = await keyGenerator.generateSymKey();
      const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params);
      const input: cryptoFramework.DataBlob = { data: plainData };
      const output = await cipher.doFinal(input);
      const gcmOutput = this.normalizeGcmEncryptOutput(output.data, params.authTag.data, plainData.byteLength);

      const plainPath = this.uriToPath(plan.sourceUri);
      const encryptedPath = `${plainPath}.cdenc`;
      this.writeFile(encryptedPath, this.toArrayBuffer(gcmOutput.ciphertext));

      return {
        encryptedUri: encryptedPath,
        algorithm: 'AES-256-GCM',
        kdfAlgorithm: 'NONE-RAW-KEY',
        kdfSalt: '',
        nonce: this.toHex(nonce.data),
        keyMaterial: this.toHex(key.getEncoded().data),
        authTag: this.toHex(gcmOutput.authTag),
        plainSizeBytes: plan.plainSizeBytes,
        sha256: await this.sha256(plainData)
      };
    } catch (error) {
      throw new Error(`加密失败：${String(error)}`);
    }
  }

  async decryptFile(plan: DecryptionPlan): Promise<DecryptionResult> {
    try {
      const encryptedData = this.readFile(plan.encryptedUri);
      const keyData: cryptoFramework.DataBlob = { data: this.fromHex(plan.keyMaterial) };
      const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const key = await keyGenerator.convertKey(keyData);
      const nonceBlob: cryptoFramework.DataBlob = { data: this.fromHex(plan.nonce) };
      const aadBlob: cryptoFramework.DataBlob = { data: this.toBytes('coursedrop:file:v1') };
      const authTagBlob: cryptoFramework.DataBlob = { data: this.fromHex(plan.authTag) };
      const params: cryptoFramework.GcmParamsSpec = {
        algName: 'GcmParamsSpec',
        iv: nonceBlob,
        aad: aadBlob,
        authTag: authTagBlob
      };
      const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
      let output: cryptoFramework.DataBlob;
      try {
        output = await cipher.doFinal({ data: encryptedData });
      } catch (error) {
        output = await this.decryptLegacyCombinedGcm(encryptedData, plan);
      }

      const encryptedName = this.fileNameFromUri(plan.encryptedUri).replace(/\.cdenc$/, '');
      const targetPath = `${plan.targetDirectory.replace(/\/$/, '')}/decrypted-${encryptedName}`;
      this.writeFile(targetPath, this.toArrayBuffer(output.data));
      return {
        plainUri: targetPath,
        plainSizeBytes: output.data.byteLength
      };
    } catch (error) {
      throw new Error(`解密失败：${String(error)}`);
    }
  }

  private readFile(uri: string): Uint8Array {
    const path = this.uriToPath(uri);
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(path);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      return new Uint8Array(buffer);
    } finally {
      fileIo.closeSync(file.fd);
    }
  }

  private writeFile(path: string, data: ArrayBuffer): void {
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.READ_WRITE);
    try {
      fileIo.writeSync(file.fd, data);
    } finally {
      fileIo.closeSync(file.fd);
    }
  }

  private async sha256(data: Uint8Array): Promise<string> {
    const md = cryptoFramework.createMd('SHA256');
    const input: cryptoFramework.DataBlob = { data: data };
    await md.update(input);
    const digest = await md.digest();
    return this.toHex(digest.data);
  }

  private normalizeGcmEncryptOutput(output: Uint8Array, authTag: Uint8Array, plainSizeBytes: number): GcmCipherParts {
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

  private async decryptLegacyCombinedGcm(encryptedData: Uint8Array, plan: DecryptionPlan): Promise<cryptoFramework.DataBlob> {
    if (encryptedData.byteLength <= 16) {
      throw new Error('密文长度不足');
    }
    const ciphertext = encryptedData.slice(0, encryptedData.byteLength - 16);
    const authTag = encryptedData.slice(encryptedData.byteLength - 16);
    const keyData: cryptoFramework.DataBlob = { data: this.fromHex(plan.keyMaterial) };
    const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const key = await keyGenerator.convertKey(keyData);
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: this.fromHex(plan.nonce) },
      aad: { data: this.toBytes('coursedrop:file:v1') },
      authTag: { data: this.isAllZero(this.fromHex(plan.authTag)) ? authTag : this.fromHex(plan.authTag) }
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

  private uriToPath(uri: string): string {
    if (!uri.startsWith('file://')) {
      return uri;
    }
    return decodeURIComponent(uri.replace(/^file:\/\//, ''));
  }

  private fileNameFromUri(uri: string): string {
    const path = this.uriToPath(uri);
    const parts = path.split('/');
    return parts[parts.length - 1];
  }

  private toBytes(text: string): Uint8Array {
    const bytes = new Uint8Array(text.length);
    for (let index = 0; index < text.length; index += 1) {
      bytes[index] = text.charCodeAt(index);
    }
    return bytes;
  }

  private toArrayBuffer(bytes: Uint8Array): ArrayBuffer {
    const buffer = new ArrayBuffer(bytes.byteLength);
    const target = new Uint8Array(buffer);
    target.set(bytes);
    return buffer;
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
}

interface GcmCipherParts {
  ciphertext: Uint8Array;
  authTag: Uint8Array;
}
