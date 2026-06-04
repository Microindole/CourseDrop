import { apiClient } from '../services/ApiClient';
import { identityService } from '../services/identity';
import { RelayShareApi, RelayShareDownloadResponse, RelayShareItemResponse } from '../services/share';
import { transferService } from '../services/transfer';
import { TransferTask } from '../models/TransferTask';

export class ShareDownloadViewModel {
  private relayShareApi: RelayShareApi = new RelayShareApi(apiClient);
  code: string = '';
  private e2eeKeys: E2eeItemKey[] = [];
  share: RelayShareDownloadResponse | undefined = undefined;
  tasks: TransferTask[] = [];
  loading: boolean = false;
  lastActionText: string = '输入或扫码分享码后，可下载到 CourseDrop 本地库';
  errorMessage: string = '';

  async load(code: string): Promise<void> {
    this.e2eeKeys = this.parseE2eeKeys(code);
    const normalizedCode = this.extractCode(code.trim());
    if (normalizedCode.length === 0) {
      this.errorMessage = '请输入分享码';
      this.lastActionText = '分享码为空';
      return;
    }
    this.loading = true;
    this.code = normalizedCode;
    try {
      this.share = await this.relayShareApi.getShareByCode(normalizedCode);
      this.lastActionText = `已读取分享：${this.share.items.length} 项`;
      this.errorMessage = '';
    } catch (error) {
      this.lastActionText = '读取分享失败';
      this.errorMessage = String(error);
    }
    this.loading = false;
  }

  async downloadItem(item: RelayShareItemResponse): Promise<void> {
    if (this.code.length === 0) {
      this.errorMessage = '请先读取分享';
      return;
    }
    this.loading = true;
    try {
      let identity = identityService.getLocalIdentity();
      if (identity === undefined || identity.fingerprintId.length === 0) {
        identity = await identityService.registerCurrentDevice();
      }
      const task = await transferService.downloadShareItem({
        code: this.code,
        itemId: item.id,
        encrypted: item.encrypted,
        displayName: item.displayName,
        contentType: item.contentType,
        fingerprintId: identity === undefined ? undefined : identity.fingerprintId,
        accountId: identity === undefined || identity.accountId.length === 0 ? undefined : identity.accountId,
        e2eeKeyMaterial: this.findKey(item.id).keyMaterial,
        e2eeNonce: this.findKey(item.id).nonce,
        e2eeAuthTag: this.findKey(item.id).authTag
      });
      this.tasks = transferService.listTasks();
      this.lastActionText = task.status === 'COMPLETED' ? '文件已下载并写入本地库' : '下载任务已结束';
      this.errorMessage = task.status === 'FAILED' && task.errorMessage !== undefined ? task.errorMessage : '';
    } catch (error) {
      this.lastActionText = '下载失败';
      this.errorMessage = String(error);
    }
    this.loading = false;
  }

  getItems(): RelayShareItemResponse[] {
    if (this.share === undefined) {
      return [];
    }
    return this.share.items;
  }

  private extractCode(rawText: string): string {
    const marker = '/s/';
    const markerIndex = rawText.indexOf(marker);
    let code = rawText;
    if (markerIndex >= 0) {
      code = rawText.substring(markerIndex + marker.length);
    }
    const queryIndex = code.indexOf('?');
    const hashIndex = code.indexOf('#');
    let end = code.length;
    if (queryIndex >= 0 && queryIndex < end) {
      end = queryIndex;
    }
    if (hashIndex >= 0 && hashIndex < end) {
      end = hashIndex;
    }
    return code.substring(0, end).trim();
  }

  private parseE2eeKeys(rawText: string): E2eeItemKey[] {
    const marker = '#cdkey=';
    const markerIndex = rawText.indexOf(marker);
    const keys: E2eeItemKey[] = [];
    if (markerIndex < 0) {
      return keys;
    }
    const encoded = rawText.substring(markerIndex + marker.length);
    const decoded = decodeURIComponent(encoded);
    const entries = decoded.split(',');
    for (let index = 0; index < entries.length; index += 1) {
      const parts = entries[index].split(':');
      if (parts.length === 4) {
        keys.push({
          itemId: parts[0],
          keyMaterial: parts[1],
          nonce: parts[2],
          authTag: parts[3]
        });
      }
    }
    return keys;
  }

  private findKey(itemId: string): E2eeItemKey {
    for (let index = 0; index < this.e2eeKeys.length; index += 1) {
      if (this.e2eeKeys[index].itemId === itemId) {
        return this.e2eeKeys[index];
      }
    }
    return {
      itemId: itemId,
      keyMaterial: '',
      nonce: '',
      authTag: ''
    };
  }
}

interface E2eeItemKey {
  itemId: string;
  keyMaterial: string;
  nonce: string;
  authTag: string;
}
