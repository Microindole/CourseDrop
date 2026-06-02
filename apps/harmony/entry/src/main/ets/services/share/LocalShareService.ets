import { TransferItemType } from '../../models/CommonTypes';
import { ShareSession } from '../../models/ShareSession';
import { TransferItem } from '../../models/TransferItem';
import { TransferTask } from '../../models/TransferTask';
import { LocalFileEntry } from '../../models/LocalFileEntry';
import { LocalFileIndexRepository } from '../local/LocalFileIndexRepository';
import { ShareOperationResult, ShareService, TransferStats } from './ShareService';
import { ShareSessionRepository } from './ShareSessionRepository';
import { TransferTaskRepository } from './TransferTaskRepository';
import { RelayShareApi } from './RelayShareApi';
import { identityService } from '../identity';

export class LocalShareService implements ShareService {
  private sessionRepository: ShareSessionRepository;
  private taskRepository: TransferTaskRepository;
  private relayShareApi: RelayShareApi;
  private fileIndexRepository: LocalFileIndexRepository;

  constructor(
    sessionRepository: ShareSessionRepository,
    taskRepository: TransferTaskRepository,
    relayShareApi: RelayShareApi,
    fileIndexRepository: LocalFileIndexRepository
  ) {
    this.sessionRepository = sessionRepository;
    this.taskRepository = taskRepository;
    this.relayShareApi = relayShareApi;
    this.fileIndexRepository = fileIndexRepository;
  }

  listRecentSessions(limit: number): ShareSession[] {
    const now = Date.now();
    return this.sessionRepository.list()
      .filter((session: ShareSession) => session.status === 'ACTIVE')
      .filter((session: ShareSession) => session.code.length > 0)
      .filter((session: ShareSession) => session.expiresAt.length === 0 || Date.parse(session.expiresAt) > now)
      .sort((left: ShareSession, right: ShareSession) => Date.parse(right.createdAt) - Date.parse(left.createdAt))
      .slice(0, limit);
  }

  getCurrentSession(): ShareSession {
    return this.sessionRepository.current();
  }

  listTasks(sessionId: string): TransferTask[] {
    return this.taskRepository.listBySession(sessionId);
  }

  getStats(): TransferStats {
    const tasks = this.taskRepository.listAll();
    const sessions = this.sessionRepository.list();
    return {
      activeCount: tasks.filter((task) => task.status === 'RUNNING').length,
      completedCount: tasks.filter((task) => task.status === 'COMPLETED').length,
      failedCount: tasks.filter((task) => task.status === 'FAILED').length,
      expiringCount: sessions.filter((session) => session.expireStatus === 'EXPIRING_SOON').length
    };
  }

  refreshShareCode(sessionId: string): ShareOperationResult {
    const session = this.findSession(sessionId);
    if (session.items.length === 0) {
      return {
        success: false,
        message: '请先添加本地内容'
      };
    }
    return {
      success: false,
      message: '请点击创建公网分享'
    };
  }

  async createRelayShare(sessionId: string, expireHours: number, downloadPolicy: string): Promise<ShareOperationResult> {
    const draft = this.findSession(sessionId);
    if (draft.items.length === 0) {
      return {
        success: false,
        message: '请先添加本地内容'
      };
    }
    try {
      const identity = identityService.getLocalIdentity();
      const ownerIdentityId = identity === undefined ? '' : identity.fingerprintId;
      const ownerIdentityType = identity === undefined ? 'ANONYMOUS' : 'FINGERPRINT';
      const response = await this.relayShareApi.createShare(
        expireHours,
        downloadPolicy,
        ownerIdentityId,
        ownerIdentityType
      );
      const activeSession: ShareSession = {
        id: response.id,
        title: draft.title,
        code: response.code,
        shareUrl: response.downloadUrl,
        status: 'ACTIVE',
        networkMode: 'RELAY',
        expireStatus: 'ACTIVE',
        createdAt: response.createdAt,
        expiresAt: response.expiresAt,
        itemCount: draft.itemCount,
        totalSizeBytes: draft.totalSizeBytes,
        encrypted: draft.encrypted,
        downloadPolicy: response.downloadPolicy === 'OWNER_ONLY' ? 'OWNER_ONLY' :
        response.downloadPolicy === 'PUBLIC' ? 'PUBLIC' : 'LOGIN_REQUIRED',
        items: this.cloneItemsForSession(draft.items, response.id)
      };
      this.sessionRepository.setCurrent(activeSession);
      return {
        success: true,
        message: '公网分享已创建'
      };
    } catch (error) {
      return {
        success: false,
        message: `创建失败：${String(error)}`
      };
    }
  }

  async revokeShare(sessionId: string): Promise<ShareOperationResult> {
    const session = this.findSession(sessionId);
    if (session.status === 'ACTIVE') {
      try {
        await this.relayShareApi.revokeShare(session.id);
      } catch (error) {
        return {
          success: false,
          message: `撤回失败：${String(error)}`
        };
      }
    }
    session.code = '';
    session.shareUrl = '';
    session.status = 'DRAFT';
    session.networkMode = 'LAN';
    session.expireStatus = 'ACTIVE';
    session.createdAt = new Date().toISOString();
    session.expiresAt = '';
    for (let index = 0; index < session.items.length; index += 1) {
      const item = session.items[index];
      item.remoteItemId = '';
      item.remoteUrl = '';
      item.expiresAt = '';
    }
    this.sessionRepository.save(session);
    return {
      success: true,
      message: '已返回草稿状态，可重新生成链接'
    };
  }

  returnToDraft(_sessionId: string): ShareOperationResult {
    this.sessionRepository.startNewDraft();
    return {
      success: true,
      message: '已返回新的分享草稿，已生成链接仍可访问'
    };
  }

  async extendShare(sessionId: string, expireHours: number): Promise<ShareOperationResult> {
    const session = this.findSession(sessionId);
    if (session.status !== 'ACTIVE') {
      return {
        success: false,
        message: '只有已创建的公网分享可以续期'
      };
    }
    try {
      const response = await this.relayShareApi.extendShare(session.id, expireHours);
      session.expiresAt = response.expiresAt;
      session.expireStatus = 'ACTIVE';
      session.downloadPolicy = response.downloadPolicy === 'OWNER_ONLY' ? 'OWNER_ONLY' :
        response.downloadPolicy === 'PUBLIC' ? 'PUBLIC' : 'LOGIN_REQUIRED';
      if (response.downloadUrl.length > 0) {
        session.shareUrl = response.downloadUrl;
      }
      this.sessionRepository.save(session);
      return {
        success: true,
        message: '分享已续期'
      };
    } catch (error) {
      return {
        success: false,
        message: `续期失败：${String(error)}`
      };
    }
  }

  addLocalItem(_sessionId: string, _type: TransferItemType): ShareOperationResult {
    return {
      success: false,
      message: '请先接入系统文件选择器'
    };
  }

  attachLocalFile(sessionId: string, localFileId: string): ShareOperationResult {
    const session = this.findSession(sessionId);
    const localFile = this.fileIndexRepository.findById(localFileId);
    if (localFile === undefined) {
      return {
        success: false,
        message: '本地文件不存在'
      };
    }
    const duplicated = session.items.find((item) => item.localUri === localFile.localUri);
    if (duplicated !== undefined) {
      return {
        success: false,
        message: '该文件已在当前分享中'
      };
    }
    const item = this.toTransferItem(session.id, localFile);
    session.items.push(item);
    session.itemCount = session.items.length;
    session.totalSizeBytes = session.totalSizeBytes + item.sizeBytes;
    session.title = session.itemCount === 1 ? item.displayName : `${session.itemCount} 个文件`;
    this.sessionRepository.save(session);
    return {
      success: true,
      message: '已加入分享草稿'
    };
  }

  removeDraftItem(sessionId: string, itemId: string): ShareOperationResult {
    const session = this.findSession(sessionId);
    const item = session.items.find((next) => next.id === itemId);
    if (item === undefined) {
      return {
        success: false,
        message: '分享项不存在'
      };
    }
    if (item.remoteItemId !== undefined && item.remoteItemId.length > 0) {
      return {
        success: false,
        message: '已上传的分享项暂不支持从客户端单独删除'
      };
    }
    session.items = session.items.filter((next) => next.id !== itemId);
    session.itemCount = session.items.length;
    session.totalSizeBytes = this.sumItemSize(session.items);
    session.title = session.itemCount === 0 ? '新的 CourseDrop 分享' :
      session.itemCount === 1 ? session.items[0].displayName : `${session.itemCount} 个文件`;
    this.sessionRepository.save(session);
    return {
      success: true,
      message: '已从草稿移除'
    };
  }

  clearDraft(sessionId: string): ShareOperationResult {
    const session = this.findSession(sessionId);
    if (session.status === 'ACTIVE') {
      return {
        success: false,
        message: '已创建的公网分享不能直接清空草稿，请先返回新草稿'
      };
    }
    session.items = [];
    session.itemCount = 0;
    session.totalSizeBytes = 0;
    session.title = '新的 CourseDrop 分享';
    this.sessionRepository.save(session);
    return {
      success: true,
      message: '分享草稿已清空'
    };
  }

  markItemUploaded(
    sessionId: string,
    itemId: string,
    remoteItemId: string,
    remoteUrl: string,
    expiresAt: string
  ): ShareOperationResult {
    const session = this.findSession(sessionId);
    const item = session.items.find((next) => next.id === itemId);
    if (item === undefined) {
      return {
        success: false,
        message: '分享项不存在'
      };
    }
    item.remoteItemId = remoteItemId;
    item.remoteUrl = remoteUrl;
    item.expiresAt = expiresAt;
    this.sessionRepository.save(session);
    return {
      success: true,
      message: '分享项已上传'
    };
  }

  updateShareUrl(sessionId: string, shareUrl: string): ShareOperationResult {
    const session = this.findSession(sessionId);
    session.shareUrl = shareUrl;
    this.sessionRepository.save(session);
    return {
      success: true,
      message: '分享链接已更新'
    };
  }

  private findSession(sessionId: string): ShareSession {
    const session = this.sessionRepository.list().find((next) => next.id === sessionId);
    if (session === undefined) {
      throw new Error(`share session not found: ${sessionId}`);
    }
    return session;
  }

  private toTransferItem(sessionId: string, file: LocalFileEntry): TransferItem {
    return {
      id: file.id,
      sessionId: sessionId,
      type: file.type,
      displayName: file.displayName,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      localUri: file.localUri,
      remoteItemId: '',
      remoteUrl: '',
      createdAt: new Date().toISOString(),
      expiresAt: '',
      encrypted: file.encrypted
    };
  }

  private cloneItemsForSession(items: TransferItem[], sessionId: string): TransferItem[] {
    const clonedItems: TransferItem[] = [];
    for (let index = 0; index < items.length; index += 1) {
      const item = items[index];
      clonedItems.push({
        id: item.id,
        sessionId: sessionId,
        type: item.type,
        displayName: item.displayName,
        contentType: item.contentType,
        sizeBytes: item.sizeBytes,
        localUri: item.localUri,
        remoteItemId: '',
        remoteUrl: '',
        createdAt: item.createdAt,
        expiresAt: '',
        encrypted: item.encrypted
      });
    }
    return clonedItems;
  }

  private sumItemSize(items: TransferItem[]): number {
    let total = 0;
    for (let index = 0; index < items.length; index += 1) {
      total += items[index].sizeBytes;
    }
    return total;
  }
}
