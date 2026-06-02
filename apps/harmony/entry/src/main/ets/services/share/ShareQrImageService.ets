import http from '@ohos.net.http';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { ApiClient } from '../ApiClient';
import { CourseDropFileStore } from '../local/CourseDropFileStore';
import { FileSystemService } from '../file';

export class ShareQrImageService {
  private apiClient: ApiClient;
  private fileStore: CourseDropFileStore;
  private fileSystemService: FileSystemService;

  constructor(apiClient: ApiClient, fileStore: CourseDropFileStore, fileSystemService: FileSystemService) {
    this.apiClient = apiClient;
    this.fileStore = fileStore;
    this.fileSystemService = fileSystemService;
  }

  async loadQrImage(shareUrl: string): Promise<string> {
    if (shareUrl.length === 0 || !this.apiClient.hasBaseUrl()) {
      return '';
    }
    const cacheRoot = this.fileStore.cacheRoot();
    if (cacheRoot.length === 0) {
      throw new Error('App 缓存目录未初始化');
    }
    this.fileSystemService.ensureDirectory(cacheRoot);
    const targetPath = `${cacheRoot}/share-qr-${this.safeKey(shareUrl)}.png`;
    const png = await this.downloadPng(shareUrl);
    const file = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.READ_WRITE);
    try {
      fileIo.writeSync(file.fd, png);
    } finally {
      fileIo.closeSync(file.fd);
    }
    return fileUri.getUriFromPath(targetPath);
  }

  private async downloadPng(shareUrl: string): Promise<ArrayBuffer> {
    const primaryUrl = `${this.apiClient.getBaseUrl()}/api/qr/png?text=${encodeURIComponent(shareUrl)}`;
    const fallbackUrl = `${this.apiClient.getBaseUrl()}/api/qr.png?text=${encodeURIComponent(shareUrl)}`;
    try {
      return await this.requestPng(primaryUrl);
    } catch (error) {
      const message = String(error);
      if (message.indexOf('HTTP 404') < 0) {
        throw new Error(message);
      }
      return await this.requestPng(fallbackUrl);
    }
  }

  private async requestPng(url: string): Promise<ArrayBuffer> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 15000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`二维码 HTTP ${response.responseCode}: ${String(response.result)}`);
      }
      const buffer = response.result as ArrayBuffer;
      if (buffer.byteLength <= 0) {
        throw new Error('二维码响应为空');
      }
      return buffer;
    } finally {
      request.destroy();
    }
  }

  private safeKey(text: string): string {
    let hash = 0;
    for (let index = 0; index < text.length; index += 1) {
      hash = ((hash << 5) - hash + text.charCodeAt(index)) | 0;
    }
    return `${Date.now()}-${Math.abs(hash)}`;
  }
}
