import { ShareSession } from '../../models/ShareSession';
import { TransferItem } from '../../models/TransferItem';
import { appPreferencesStore } from '../../common/AppPreferencesStore';

const KEY_SHARE_SESSIONS: string = 'share.sessions';
const KEY_CURRENT_SHARE_SESSION_ID: string = 'share.currentSessionId';

export interface ShareSessionRepository {
  list(): ShareSession[];
  current(): ShareSession;
  save(session: ShareSession): void;
  setCurrent(session: ShareSession): void;
  startNewDraft(): ShareSession;
}

export class LocalShareSessionRepository implements ShareSessionRepository {
  private currentSession: ShareSession = this.createDraftSession();
  private sessions: ShareSession[] = [this.currentSession];

  list(): ShareSession[] {
    return this.sessions;
  }

  current(): ShareSession {
    return this.currentSession;
  }

  save(session: ShareSession): void {
    const index = this.sessions.findIndex((next) => next.id === session.id);
    if (index < 0) {
      this.sessions.push(session);
      return;
    }
    this.sessions[index] = session;
    if (this.currentSession.id === session.id) {
      this.currentSession = session;
    }
  }

  setCurrent(session: ShareSession): void {
    this.save(session);
    this.currentSession = session;
  }

  startNewDraft(): ShareSession {
    const draft = this.createDraftSession();
    this.currentSession = draft;
    this.sessions.push(draft);
    return draft;
  }

  private createDraftSession(): ShareSession {
    const createdAt = new Date().toISOString();
    return {
      id: `draft-${Date.now()}-${Math.floor(Math.random() * 100000)}`,
      title: '',
      code: '',
      shareUrl: '',
      status: 'DRAFT',
      networkMode: 'LAN',
      expireStatus: 'ACTIVE',
      createdAt: createdAt,
      expiresAt: '',
      itemCount: 0,
      totalSizeBytes: 0,
      encrypted: true,
      items: []
    };
  }
}

export class PreferencesShareSessionRepository implements ShareSessionRepository {
  private currentSession: ShareSession = this.createDraftSession();
  private sessions: ShareSession[] = [];
  private loaded: boolean = false;

  list(): ShareSession[] {
    this.ensureLoaded();
    return this.sessions.map((session: ShareSession) => this.copySession(session));
  }

  current(): ShareSession {
    this.ensureLoaded();
    return this.copySession(this.currentSession);
  }

  save(session: ShareSession): void {
    this.ensureLoaded();
    const copy = this.copySession(session);
    const index = this.sessions.findIndex((next: ShareSession) => next.id === copy.id);
    if (index < 0) {
      this.sessions.push(copy);
    } else {
      this.sessions[index] = copy;
    }
    if (this.currentSession.id === copy.id) {
      this.currentSession = this.copySession(copy);
    }
    this.persist();
  }

  setCurrent(session: ShareSession): void {
    this.ensureLoaded();
    const copy = this.copySession(session);
    this.save(copy);
    this.currentSession = this.copySession(copy);
    appPreferencesStore.putString(KEY_CURRENT_SHARE_SESSION_ID, this.currentSession.id);
  }

  startNewDraft(): ShareSession {
    this.ensureLoaded();
    const draft = this.createDraftSession();
    this.currentSession = this.copySession(draft);
    this.sessions.push(this.copySession(draft));
    this.persist();
    appPreferencesStore.putString(KEY_CURRENT_SHARE_SESSION_ID, draft.id);
    return this.copySession(draft);
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_SHARE_SESSIONS, '');
    if (jsonText.length > 0) {
      try {
        const loadedSessions = JSON.parse(jsonText) as ShareSession[];
        this.sessions = loadedSessions.map((session: ShareSession) => this.copySession(session));
      } catch (error) {
        console.error(`[CourseDrop] load share sessions failed: ${String(error)}`);
        this.sessions = [];
      }
    }
    if (this.sessions.length === 0) {
      const draft = this.createDraftSession();
      this.sessions = [draft];
      this.currentSession = this.copySession(draft);
      this.persist();
      appPreferencesStore.putString(KEY_CURRENT_SHARE_SESSION_ID, draft.id);
      return;
    }
    const currentId = appPreferencesStore.getString(KEY_CURRENT_SHARE_SESSION_ID, '');
    const current = this.sessions.find((session: ShareSession) => session.id === currentId);
    if (current !== undefined) {
      this.currentSession = this.copySession(current);
      return;
    }
    const latestDraft = this.sessions.find((session: ShareSession) => session.status === 'DRAFT');
    this.currentSession = this.copySession(latestDraft === undefined ? this.sessions[0] : latestDraft);
    appPreferencesStore.putString(KEY_CURRENT_SHARE_SESSION_ID, this.currentSession.id);
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_SHARE_SESSIONS, JSON.stringify(this.sessions));
  }

  private createDraftSession(): ShareSession {
    const createdAt = new Date().toISOString();
    return {
      id: `draft-${Date.now()}-${Math.floor(Math.random() * 100000)}`,
      title: '新的 CourseDrop 分享',
      code: '',
      shareUrl: '',
      status: 'DRAFT',
      networkMode: 'LAN',
      expireStatus: 'ACTIVE',
      createdAt: createdAt,
      expiresAt: '',
      itemCount: 0,
      totalSizeBytes: 0,
      encrypted: true,
      items: []
    };
  }

  private copySession(session: ShareSession): ShareSession {
    return {
      id: session.id,
      title: session.title,
      code: session.code,
      shareUrl: session.shareUrl,
      status: session.status,
      networkMode: session.networkMode,
      expireStatus: session.expireStatus,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      itemCount: session.itemCount,
      totalSizeBytes: session.totalSizeBytes,
      encrypted: session.encrypted,
      downloadPolicy: session.downloadPolicy,
      items: session.items.map((item: TransferItem) => this.copyItem(item))
    };
  }

  private copyItem(item: TransferItem): TransferItem {
    return {
      id: item.id,
      roomId: item.roomId,
      sessionId: item.sessionId,
      type: item.type,
      displayName: item.displayName,
      contentType: item.contentType,
      sizeBytes: item.sizeBytes,
      localUri: item.localUri,
      remoteUrl: item.remoteUrl,
      remoteItemId: item.remoteItemId,
      createdAt: item.createdAt,
      expiresAt: item.expiresAt,
      encrypted: item.encrypted
    };
  }
}
