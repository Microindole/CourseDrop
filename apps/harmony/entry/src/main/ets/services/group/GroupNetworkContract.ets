import http from '@ohos.net.http';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import {
  GroupCreateRequest,
  GroupCreateResponse,
  GroupMember,
  GroupMessage,
  GroupMessageSyncResult
} from '../../models/Group';
import { ApiClient } from '../ApiClient';
import { FileSystemService } from '../file';
import { identityService } from '../identity';

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
  expiryHours?: number;
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

export class HttpGroupNetworkContract implements GroupNetworkContract {
  private apiClient: ApiClient;
  private fileSystemService: FileSystemService;

  constructor(apiClient: ApiClient, fileSystemService: FileSystemService) {
    this.apiClient = apiClient;
    this.fileSystemService = fileSystemService;
  }

  async createGroup(request: GroupCreateRequest): Promise<GroupCreateResponse> {
    const responseText = await this.apiClient.postJson('/api/groups', JSON.stringify(request));
    return JSON.parse(responseText) as GroupCreateResponse;
  }

  async getGroup(groupId: string): Promise<GroupCreateResponse> {
    const responseText = await this.apiClient.get(`/api/groups/${groupId}`);
    return JSON.parse(responseText) as GroupCreateResponse;
  }

  async joinGroup(groupId: string, fingerprintId: string): Promise<GroupMember> {
    const responseText = await this.apiClient.postJson(`/api/groups/${groupId}/join`, JSON.stringify({
      fingerprintId: fingerprintId
    }));
    return JSON.parse(responseText) as GroupMember;
  }

  async leaveGroup(groupId: string, fingerprintId: string): Promise<void> {
    const headers: FingerprintHeader = {
      'X-CourseDrop-Fingerprint-Id': fingerprintId
    };
    await this.apiClient.delete(`/api/groups/${groupId}/members/me`, headers);
  }

  async sendMessage(groupId: string, message: GroupMessage): Promise<GroupMessage> {
    const responseText = await this.apiClient.postJson(`/api/groups/${groupId}/messages`, JSON.stringify({
      id: message.id,
      senderId: message.senderId,
      type: message.type,
      iv: message.iv,
      authTag: message.authTag,
      encryptedPayload: message.encryptedPayload
    }));
    return JSON.parse(responseText) as GroupMessage;
  }

  async syncMessages(groupId: string, cursor: string): Promise<GroupMessageSyncResult> {
    const identity = identityService.getLocalIdentity();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    const headers: FingerprintHeader = {
      'X-CourseDrop-Fingerprint-Id': identity.fingerprintId
    };
    const suffix = cursor.length === 0 ? '' : `?after=${encodeURIComponent(cursor)}`;
    const responseText = await this.apiClient.get(`/api/groups/${groupId}/messages${suffix}`, headers);
    return JSON.parse(responseText) as GroupMessageSyncResult;
  }

  async uploadFile(request: GroupFileUploadRequest): Promise<GroupFileUploadResponse> {
    const identity = identityService.getLocalIdentity();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    const boundary = `----CourseDropGroup${Date.now()}`;
    const body = this.buildMultipartBody(request, boundary);
    const httpRequest = http.createHttp();
    const url = `${this.apiClient.getBaseUrl()}/api/groups/${request.groupId}/files`;
    const headers: MultipartHeader = {
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
      'Content-Length': `${body.byteLength}`,
      'X-CourseDrop-Fingerprint-Id': identity.fingerprintId
    };
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: body,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}: ${String(response.result)}`);
      }
      const raw = JSON.parse(String(response.result)) as GroupFileServerResponse;
      return {
        fileId: raw.id,
        groupId: raw.groupId,
        sizeBytes: raw.sizeBytes,
        expiresAt: raw.expiresAt
      };
    } finally {
      httpRequest.destroy();
    }
  }

  async downloadFile(request: GroupFileDownloadRequest): Promise<GroupFileDownloadResponse> {
    const identity = identityService.getLocalIdentity();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    const headers: FingerprintHeader = {
      'X-CourseDrop-Fingerprint-Id': identity.fingerprintId
    };
    const httpRequest = http.createHttp();
    const url = `${this.apiClient.getBaseUrl()}/api/groups/${request.groupId}/files/${request.fileId}/download`;
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}: ${String(response.result)}`);
      }
      this.fileSystemService.ensureDirectory(request.targetDirectory);
      const targetPath = `${request.targetDirectory}/${Date.now()}-group-${request.fileId}.bin`;
      const buffer = response.result as ArrayBuffer;
      const file = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      try {
        fileIo.writeSync(file.fd, buffer);
      } finally {
        fileIo.closeSync(file.fd);
      }
      return {
        localUri: fileUri.getUriFromPath(targetPath),
        sizeBytes: buffer.byteLength
      };
    } finally {
      httpRequest.destroy();
    }
  }

  private buildMultipartBody(request: GroupFileUploadRequest, boundary: string): ArrayBuffer {
    const fileData = this.fileSystemService.readAll(request.localUri);
    const fields = this.buildFieldParts(request, boundary);
    const fileHeader = this.toUtf8(
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="file"; filename="${this.escapeMultipartValue(request.displayName)}"\r\n` +
      `Content-Type: ${request.contentType}\r\n\r\n`
    );
    const lineBreak = this.toUtf8('\r\n');
    const end = this.toUtf8(`--${boundary}--\r\n`);
    return this.concatBuffers(fields, fileHeader, fileData, lineBreak, end);
  }

  private buildFieldParts(request: GroupFileUploadRequest, boundary: string): ArrayBuffer {
    let text = '';
    text += this.fieldPart(boundary, 'encrypted', request.encrypted ? 'true' : 'false');
    text += this.fieldPart(boundary, 'encryptionAlgorithm', request.encryptionAlgorithm);
    text += this.fieldPart(boundary, 'kdfAlgorithm', request.kdfAlgorithm);
    if (request.kdfSalt.length > 0) {
      text += this.fieldPart(boundary, 'kdfSalt', request.kdfSalt);
    }
    text += this.fieldPart(boundary, 'nonce', request.nonce);
    text += this.fieldPart(boundary, 'sha256', request.sha256);
    text += this.fieldPart(boundary, 'plainSizeBytes', `${request.plainSizeBytes}`);
    if (request.expiryHours !== undefined) {
      text += this.fieldPart(boundary, 'expiryHours', `${request.expiryHours}`);
    }
    return this.toUtf8(text);
  }

  private fieldPart(boundary: string, name: string, value: string): string {
    return `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${value}\r\n`;
  }

  private escapeMultipartValue(value: string): string {
    return value.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\r/g, '').replace(/\n/g, '');
  }

  private toUtf8(text: string): ArrayBuffer {
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
    return new Uint8Array(bytes).buffer;
  }

  private concatBuffers(
    first: ArrayBuffer,
    second: ArrayBuffer,
    third: ArrayBuffer,
    fourth: ArrayBuffer,
    fifth: ArrayBuffer
  ): ArrayBuffer {
    const totalLength = first.byteLength + second.byteLength + third.byteLength + fourth.byteLength + fifth.byteLength;
    const result = new Uint8Array(totalLength);
    let offset = 0;
    offset = this.copyBuffer(result, first, offset);
    offset = this.copyBuffer(result, second, offset);
    offset = this.copyBuffer(result, third, offset);
    offset = this.copyBuffer(result, fourth, offset);
    this.copyBuffer(result, fifth, offset);
    return result.buffer;
  }

  private copyBuffer(target: Uint8Array, source: ArrayBuffer, offset: number): number {
    target.set(new Uint8Array(source), offset);
    return offset + source.byteLength;
  }
}

interface FingerprintHeader {
  'X-CourseDrop-Fingerprint-Id': string;
}

interface MultipartHeader {
  'Content-Type': string;
  'Content-Length': string;
  'X-CourseDrop-Fingerprint-Id': string;
}

interface GroupFileServerResponse {
  id: string;
  groupId: string;
  sizeBytes: number;
  expiresAt: string;
}
