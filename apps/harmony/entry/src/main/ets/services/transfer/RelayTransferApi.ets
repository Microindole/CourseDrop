import http from '@ohos.net.http';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { ApiClient } from '../ApiClient';
import { FileSystemService } from '../file';
import { RelayDownloadRequest, RelayDownloadResult, RelayUploadRequest, RelayUploadResponse } from './TransferModels';

export interface RelayTransferApi {
  uploadShareItem(request: RelayUploadRequest): Promise<RelayUploadResponse>;
  downloadShareItem(request: RelayDownloadRequest): Promise<RelayDownloadResult>;
}

export class HttpRelayTransferApi implements RelayTransferApi {
  private apiClient: ApiClient;
  private fileSystemService: FileSystemService;

  constructor(apiClient: ApiClient, fileSystemService: FileSystemService) {
    this.apiClient = apiClient;
    this.fileSystemService = fileSystemService;
  }

  async uploadShareItem(request: RelayUploadRequest): Promise<RelayUploadResponse> {
    if (!this.apiClient.hasBaseUrl()) {
      throw new Error('未配置中转源');
    }
    const boundary = `----CourseDrop${Date.now()}`;
    const body = this.buildMultipartBody(request, boundary);
    const httpRequest = http.createHttp();
    const url = `${this.apiClient.getBaseUrl()}/api/shares/${request.shareId}/items`;
    const multipartHeader: MultipartHeader = {
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
      'Content-Length': `${body.byteLength}`
    };
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: multipartHeader,
        extraData: body,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}: ${String(response.result)}`);
      }
      return JSON.parse(String(response.result)) as RelayUploadResponse;
    } finally {
      httpRequest.destroy();
    }
  }

  async downloadShareItem(request: RelayDownloadRequest): Promise<RelayDownloadResult> {
    if (!this.apiClient.hasBaseUrl()) {
      throw new Error('未配置中转源');
    }
    const url = `${this.apiClient.getBaseUrl()}/api/shares/${request.code}/items/${request.itemId}/download`;
    if (request.accountId !== undefined && request.accountId.length > 0) {
      const headers: AccountDownloadHeader = {
        'X-CourseDrop-Account-Id': request.accountId
      };
      return await this.requestDownload(url, request, headers);
    }
    if (request.fingerprintId !== undefined && request.fingerprintId.length > 0) {
      const headers: FingerprintDownloadHeader = {
        'X-CourseDrop-Fingerprint-Id': request.fingerprintId
      };
      return await this.requestDownload(url, request, headers);
    }
    return await this.requestDownload(url, request);
  }

  private async requestDownload(
    url: string,
    request: RelayDownloadRequest,
    headers?: Object
  ): Promise<RelayDownloadResult> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const displayName = request.displayName.length === 0 ? `downloaded-${request.itemId}` : request.displayName;
      const contentType = request.contentType.length === 0 ? 'application/octet-stream' : request.contentType;

      const buffer = response.result as ArrayBuffer;
      const sizeBytes = buffer.byteLength;

      this.fileSystemService.ensureDirectory(request.targetDirectory);
      const targetPath = `${request.targetDirectory}/${Date.now()}-${this.escapeLocalFileName(displayName)}`;

      const file = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      try {
        fileIo.writeSync(file.fd, buffer);
      } finally {
        fileIo.closeSync(file.fd);
      }

      return {
        localUri: fileUri.getUriFromPath(targetPath),
        displayName: displayName,
        sizeBytes: sizeBytes,
        contentType: contentType
      };
    } finally {
      httpRequest.destroy();
    }
  }

  private buildMultipartBody(request: RelayUploadRequest, boundary: string): ArrayBuffer {
    const fileData = this.fileSystemService.readAll(request.localUri);
    const fields = this.buildFieldParts(request, boundary);
    const filename = this.escapeMultipartValue(request.displayName);
    const fileHeader = this.toUtf8(
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="file"; filename="${filename}"\r\n` +
      `Content-Type: ${request.contentType}\r\n\r\n`
    );
    const lineBreak = this.toUtf8('\r\n');
    const end = this.toUtf8(`--${boundary}--\r\n`);
    return this.concatBuffers(fields, fileHeader, fileData, lineBreak, end);
  }

  private buildFieldParts(request: RelayUploadRequest, boundary: string): ArrayBuffer {
    let text = '';
    text += this.fieldPart(boundary, 'encrypted', request.encrypted ? 'true' : 'false');
    if (request.sha256 !== undefined) {
      text += this.fieldPart(boundary, 'sha256', request.sha256);
    }
    if (request.encryptionAlgorithm !== undefined) {
      text += this.fieldPart(boundary, 'encryptionAlgorithm', request.encryptionAlgorithm);
    }
    if (request.kdfAlgorithm !== undefined) {
      text += this.fieldPart(boundary, 'kdfAlgorithm', request.kdfAlgorithm);
    }
    if (request.kdfSalt !== undefined) {
      text += this.fieldPart(boundary, 'kdfSalt', request.kdfSalt);
    }
    if (request.nonce !== undefined) {
      text += this.fieldPart(boundary, 'nonce', request.nonce);
    }
    if (request.plainSizeBytes !== undefined) {
      text += this.fieldPart(boundary, 'plainSizeBytes', `${request.plainSizeBytes}`);
    }
    return this.toUtf8(text);
  }

  private fieldPart(boundary: string, name: string, value: string): string {
    return `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${value}\r\n`;
  }

  private escapeMultipartValue(value: string): string {
    return value.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\r/g, '').replace(/\n/g, '');
  }

  private escapeLocalFileName(value: string): string {
    return value.replace(/\//g, '_').replace(/\\/g, '_').replace(/:/g, '_').replace(/\r/g, '').replace(/\n/g, '');
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

interface MultipartHeader {
  'Content-Type': string;
  'Content-Length': string;
}

interface FingerprintDownloadHeader {
  'X-CourseDrop-Fingerprint-Id': string;
}

interface AccountDownloadHeader {
  'X-CourseDrop-Account-Id': string;
}
