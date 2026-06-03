import { TrustedDevice } from '../protocol/LanProtocolModels';
import { LanSecureSession } from '../protocol/LanProtocolModels';

export interface LanSecureChannelService {
  open(device: TrustedDevice): LanSecureSession;
  close(sessionId: string): void;
}

export class DefaultLanSecureChannelService implements LanSecureChannelService {
  private sessions: LanSecureSession[] = [];

  open(device: TrustedDevice): LanSecureSession {
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 30 * 60 * 1000);
    const session: LanSecureSession = {
      id: `secure-${Date.now()}-${Math.floor(Math.random() * 1000000)}`,
      remoteDeviceId: device.id,
      remoteAddress: device.lastAddress,
      status: 'PENDING',
      sessionKeyFingerprint: this.sessionFingerprint(device),
      createdAt: createdAt.toISOString(),
      expiresAt: expiresAt.toISOString()
    };
    this.sessions.push(session);
    return session;
  }

  close(sessionId: string): void {
    const session = this.sessions.find((next: LanSecureSession) => next.id === sessionId);
    if (session === undefined) {
      return;
    }
    session.status = 'CLOSED';
  }

  private sessionFingerprint(device: TrustedDevice): string {
    const material = `${device.id}|${device.publicKeyFingerprint}|${Date.now()}`;
    let hash = 0;
    for (let index = 0; index < material.length; index += 1) {
      hash = ((hash << 5) - hash + material.charCodeAt(index)) | 0;
    }
    return Math.abs(hash).toString(16);
  }
}
