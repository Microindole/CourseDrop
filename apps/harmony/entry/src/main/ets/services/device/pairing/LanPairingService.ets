import { Device } from '../../../models/Device';
import {
  LanPairingFactory,
  LanPairingMessage,
  LanPairingProtocol,
  LanPairingSession,
  TrustedDevice
} from '../protocol/LanProtocolModels';
import { LanPairingRepository } from './LanPairingRepository';
import { TrustedDeviceRepository } from './TrustedDeviceRepository';

export interface LanPairingService {
  startPairing(remote: Device, localDeviceId: string, localPublicKey: string): LanPairingSession;
  acceptPairing(sessionId: string, remotePublicKey: string): LanPairingSession | undefined;
  handlePairingMessage(message: LanPairingMessage, remoteAddress: string, localDeviceId: string, localPublicKey: string): LanPairingSession | undefined;
  createRequestMessage(sessionId: string, localDeviceName: string): LanPairingMessage | undefined;
  createAcceptMessage(sessionId: string, localDeviceName: string): LanPairingMessage | undefined;
  createRejectMessage(sessionId: string, localDeviceName: string, reason: string): LanPairingMessage | undefined;
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
    const session = LanPairingFactory.createPendingSession(
      'INITIATOR',
      localDeviceId,
      remote.id,
      remote.name,
      remoteAddress,
      localPublicKey
    );
    this.pairingRepository.save(session);
    return session;
  }

  createRequestMessage(sessionId: string, localDeviceName: string): LanPairingMessage | undefined {
    const session = this.pairingRepository.findById(sessionId);
    if (session === undefined) {
      return undefined;
    }
    return LanPairingProtocol.createRequest(session, localDeviceName);
  }

  createAcceptMessage(sessionId: string, localDeviceName: string): LanPairingMessage | undefined {
    const session = this.pairingRepository.findById(sessionId);
    if (session === undefined) {
      return undefined;
    }
    return LanPairingProtocol.createAccept(session, localDeviceName);
  }

  createRejectMessage(sessionId: string, localDeviceName: string, reason: string): LanPairingMessage | undefined {
    const session = this.pairingRepository.findById(sessionId);
    if (session === undefined) {
      return undefined;
    }
    return LanPairingProtocol.createReject(session, localDeviceName, reason);
  }

  acceptPairing(sessionId: string, remotePublicKey: string): LanPairingSession | undefined {
    const session = this.pairingRepository.findById(sessionId);
    if (session === undefined) {
      return undefined;
    }
    const completed = LanPairingFactory.completeHandshake(session, remotePublicKey);
    this.pairingRepository.save(completed);
    return completed;
  }

  handlePairingMessage(
    message: LanPairingMessage,
    remoteAddress: string,
    localDeviceId: string,
    localPublicKey: string
  ): LanPairingSession | undefined {
    if (message.kind === 'PAIR_ACCEPT') {
      return this.acceptPairing(message.sessionId, message.localPublicKey);
    }
    if (message.kind === 'PAIR_REJECT') {
      this.rejectPairing(message.sessionId);
      return this.pairingRepository.findById(message.sessionId);
    }
    const session = LanPairingFactory.createSession(
      'RESPONDER',
      localDeviceId,
      message.localDeviceId,
      message.localDeviceName,
      remoteAddress,
      localPublicKey,
      message.localPublicKey
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
