import { Device } from '../../../models/Device';
import {
  LanPairingFactory,
  LanPairingSession,
  TrustedDevice
} from '../protocol/LanProtocolModels';
import { LanPairingRepository } from './LanPairingRepository';
import { TrustedDeviceRepository } from './TrustedDeviceRepository';

export interface LanPairingService {
  startPairing(remote: Device, localDeviceId: string, localPublicKey: string): LanPairingSession;
  confirmPairing(sessionId: string): TrustedDevice | undefined;
  rejectPairing(sessionId: string): void;
  listSessions(): LanPairingSession[];
  listTrustedDevices(): TrustedDevice[];
}

export class DefaultLanPairingService implements LanPairingService {
  private pairingRepository: LanPairingRepository;
  private trustedRepository: TrustedDeviceRepository;

  constructor(pairingRepository: LanPairingRepository, trustedRepository: TrustedDeviceRepository) {
    this.pairingRepository = pairingRepository;
    this.trustedRepository = trustedRepository;
  }

  startPairing(remote: Device, localDeviceId: string, localPublicKey: string): LanPairingSession {
    const remoteAddress = remote.address === undefined ? '' : remote.address;
    const session = LanPairingFactory.createSession(
      'INITIATOR',
      localDeviceId,
      remote.id,
      remote.name,
      remoteAddress,
      localPublicKey,
      `remote-key-${remote.id}`
    );
    this.pairingRepository.save(session);
    return session;
  }

  confirmPairing(sessionId: string): TrustedDevice | undefined {
    const session = this.pairingRepository.findById(sessionId);
    if (session === undefined) {
      return undefined;
    }
    session.status = 'TRUSTED';
    this.pairingRepository.save(session);
    const trusted: TrustedDevice = {
      id: session.remoteDeviceId,
      name: session.remoteName,
      platform: 'HARMONY',
      publicKeyFingerprint: this.fingerprint(session.remotePublicKey),
      lastAddress: session.remoteAddress,
      trustedAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString()
    };
    this.trustedRepository.save(trusted);
    return trusted;
  }

  rejectPairing(sessionId: string): void {
    const session = this.pairingRepository.findById(sessionId);
    if (session === undefined) {
      return;
    }
    session.status = 'REJECTED';
    this.pairingRepository.save(session);
  }

  listSessions(): LanPairingSession[] {
    return this.pairingRepository.list();
  }

  listTrustedDevices(): TrustedDevice[] {
    return this.trustedRepository.list();
  }

  private fingerprint(value: string): string {
    let hash = 0;
    for (let index = 0; index < value.length; index += 1) {
      hash = ((hash << 5) - hash + value.charCodeAt(index)) | 0;
    }
    return Math.abs(hash).toString(16);
  }
}
