import { appPreferencesStore } from '../../../common/AppPreferencesStore';
import { LanPairingSession } from '../protocol/LanProtocolModels';

const KEY_PAIRING_SESSIONS: string = 'lan.pairing.sessions';

export interface LanPairingRepository {
  list(): LanPairingSession[];
  save(session: LanPairingSession): void;
  findById(id: string): LanPairingSession | undefined;
}

export class PreferencesLanPairingRepository implements LanPairingRepository {
  private sessions: LanPairingSession[] = [];
  private loaded: boolean = false;

  list(): LanPairingSession[] {
    this.ensureLoaded();
    return this.sessions.map((session: LanPairingSession) => this.copySession(session));
  }

  save(session: LanPairingSession): void {
    this.ensureLoaded();
    const copy = this.copySession(session);
    const index = this.sessions.findIndex((next: LanPairingSession) => next.id === copy.id);
    if (index < 0) {
      this.sessions.push(copy);
    } else {
      this.sessions[index] = copy;
    }
    this.persist();
  }

  findById(id: string): LanPairingSession | undefined {
    this.ensureLoaded();
    const session = this.sessions.find((next: LanPairingSession) => next.id === id);
    if (session === undefined) {
      return undefined;
    }
    return this.copySession(session);
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_PAIRING_SESSIONS, '');
    if (jsonText.length === 0) {
      return;
    }
    try {
      const loadedSessions = JSON.parse(jsonText) as LanPairingSession[];
      this.sessions = loadedSessions.map((session: LanPairingSession) => this.copySession(session));
    } catch (error) {
      console.error(`[CourseDrop] load lan pairing sessions failed: ${String(error)}`);
      this.sessions = [];
    }
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_PAIRING_SESSIONS, JSON.stringify(this.sessions));
  }

  private copySession(session: LanPairingSession): LanPairingSession {
    return {
      id: session.id,
      role: session.role,
      localDeviceId: session.localDeviceId,
      remoteDeviceId: session.remoteDeviceId,
      remoteName: session.remoteName,
      remoteAddress: session.remoteAddress,
      status: session.status,
      localPublicKey: session.localPublicKey,
      remotePublicKey: session.remotePublicKey,
      verificationCode: session.verificationCode,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt
    };
  }
}
