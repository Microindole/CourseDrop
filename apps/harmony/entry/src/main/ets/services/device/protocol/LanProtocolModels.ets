import { DevicePlatform } from '../../../models/Device';

export class LanProtocolNames {
  static readonly DISCOVERY: string = 'coursedrop.discovery.v1';
  static readonly PAIRING: string = 'coursedrop.pairing.v1';
  static readonly SECURE: string = 'coursedrop.secure.v1';
}

export type LanDiscoveryKind = 'DISCOVER' | 'ANNOUNCE';
export type LanPairingMessageKind = 'PAIR_REQUEST' | 'PAIR_ACCEPT' | 'PAIR_REJECT';
export type LanPairingStatus = 'PENDING' | 'VERIFYING' | 'TRUSTED' | 'REJECTED' | 'EXPIRED';
export type LanPairingRole = 'INITIATOR' | 'RESPONDER';
export type LanSecureChannelStatus = 'PENDING' | 'ESTABLISHED' | 'FAILED' | 'CLOSED';

export interface LanDiscoveryPayload {
  protocol: string;
  kind: LanDiscoveryKind;
  deviceId: string;
  deviceName: string;
  platform: DevicePlatform;
  responsePort: number;
  pairingPort: number;
  transferPort: number;
  capabilities: string[];
  publicKeyFingerprint: string;
  sentAt: number;
}

export interface LanPairingSession {
  id: string;
  role: LanPairingRole;
  localDeviceId: string;
  remoteDeviceId: string;
  remoteName: string;
  remoteAddress: string;
  status: LanPairingStatus;
  localPublicKey: string;
  remotePublicKey: string;
  verificationCode: string;
  createdAt: string;
  expiresAt: string;
}

export interface LanPairingMessage {
  protocol: string;
  kind: LanPairingMessageKind;
  sessionId: string;
  localDeviceId: string;
  localDeviceName: string;
  localPlatform: DevicePlatform;
  localPublicKey: string;
  remoteDeviceId: string;
  verificationCode: string;
  reason: string;
  sentAt: number;
}

export interface TrustedDevice {
  id: string;
  name: string;
  platform: DevicePlatform;
  publicKeyFingerprint: string;
  lastAddress: string;
  trustedAt: string;
  lastSeenAt: string;
}

export interface LanSecureSession {
  id: string;
  remoteDeviceId: string;
  remoteAddress: string;
  status: LanSecureChannelStatus;
  sessionKeyFingerprint: string;
  createdAt: string;
  expiresAt: string;
}

export class LanDiscoveryProtocol {
  static createPayload(
    kind: LanDiscoveryKind,
    deviceId: string,
    deviceName: string,
    responsePort: number,
    pairingPort: number,
    transferPort: number,
    publicKeyFingerprint: string
  ): LanDiscoveryPayload {
    const payload: LanDiscoveryPayload = {
      protocol: LanProtocolNames.DISCOVERY,
      kind: kind,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: 'HARMONY',
      responsePort: responsePort,
      pairingPort: pairingPort,
      transferPort: transferPort,
      capabilities: ['pairing-v1', 'secure-transfer-v1'],
      publicKeyFingerprint: publicKeyFingerprint,
      sentAt: Date.now()
    };
    return payload;
  }

  static encode(payload: LanDiscoveryPayload): string {
    return JSON.stringify(payload);
  }

  static parse(text: string): LanDiscoveryPayload | undefined {
    try {
      const payload = JSON.parse(text) as LanDiscoveryPayload;
      if (payload.protocol !== LanProtocolNames.DISCOVERY) {
        return undefined;
      }
      if (payload.kind !== 'DISCOVER' && payload.kind !== 'ANNOUNCE') {
        return undefined;
      }
      if (payload.deviceId.length === 0 || payload.deviceName.length === 0) {
        return undefined;
      }
      return payload;
    } catch (error) {
      console.error(`[CourseDrop] parse lan discovery protocol failed: ${String(error)}`);
      return undefined;
    }
  }
}

export class LanPairingFactory {
  static createSession(
    role: LanPairingRole,
    localDeviceId: string,
    remoteDeviceId: string,
    remoteName: string,
    remoteAddress: string,
    localPublicKey: string,
    remotePublicKey: string
  ): LanPairingSession {
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000);
    const session: LanPairingSession = {
      id: `pair-${Date.now()}-${Math.floor(Math.random() * 1000000)}`,
      role: role,
      localDeviceId: localDeviceId,
      remoteDeviceId: remoteDeviceId,
      remoteName: remoteName,
      remoteAddress: remoteAddress,
      status: 'VERIFYING',
      localPublicKey: localPublicKey,
      remotePublicKey: remotePublicKey,
      verificationCode: LanPairingFactory.verificationCode(localDeviceId, remoteDeviceId, localPublicKey, remotePublicKey),
      createdAt: createdAt.toISOString(),
      expiresAt: expiresAt.toISOString()
    };
    return session;
  }

  static createPendingSession(
    role: LanPairingRole,
    localDeviceId: string,
    remoteDeviceId: string,
    remoteName: string,
    remoteAddress: string,
    localPublicKey: string
  ): LanPairingSession {
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000);
    const session: LanPairingSession = {
      id: `pair-${Date.now()}-${Math.floor(Math.random() * 1000000)}`,
      role: role,
      localDeviceId: localDeviceId,
      remoteDeviceId: remoteDeviceId,
      remoteName: remoteName,
      remoteAddress: remoteAddress,
      status: 'PENDING',
      localPublicKey: localPublicKey,
      remotePublicKey: '',
      verificationCode: '',
      createdAt: createdAt.toISOString(),
      expiresAt: expiresAt.toISOString()
    };
    return session;
  }

  static completeHandshake(session: LanPairingSession, remotePublicKey: string): LanPairingSession {
    const completed: LanPairingSession = {
      id: session.id,
      role: session.role,
      localDeviceId: session.localDeviceId,
      remoteDeviceId: session.remoteDeviceId,
      remoteName: session.remoteName,
      remoteAddress: session.remoteAddress,
      status: 'VERIFYING',
      localPublicKey: session.localPublicKey,
      remotePublicKey: remotePublicKey,
      verificationCode: LanPairingFactory.verificationCode(
        session.localDeviceId,
        session.remoteDeviceId,
        session.localPublicKey,
        remotePublicKey
      ),
      createdAt: session.createdAt,
      expiresAt: session.expiresAt
    };
    return completed;
  }

  private static verificationCode(
    localDeviceId: string,
    remoteDeviceId: string,
    localPublicKey: string,
    remotePublicKey: string
  ): string {
    const localEndpoint = `${localDeviceId}:${localPublicKey}`;
    const remoteEndpoint = `${remoteDeviceId}:${remotePublicKey}`;
    const material = localEndpoint < remoteEndpoint ? `${localEndpoint}|${remoteEndpoint}` : `${remoteEndpoint}|${localEndpoint}`;
    let hash = 0;
    for (let index = 0; index < material.length; index += 1) {
      hash = ((hash << 5) - hash + material.charCodeAt(index)) | 0;
    }
    const code = Math.abs(hash) % 1000000;
    return LanPairingFactory.leftPadSix(code.toString());
  }

  private static leftPadSix(value: string): string {
    let result = value;
    while (result.length < 6) {
      result = `0${result}`;
    }
    return result;
  }
}

export class LanPairingProtocol {
  static createRequest(session: LanPairingSession, localDeviceName: string): LanPairingMessage {
    const message: LanPairingMessage = {
      protocol: LanProtocolNames.PAIRING,
      kind: 'PAIR_REQUEST',
      sessionId: session.id,
      localDeviceId: session.localDeviceId,
      localDeviceName: localDeviceName,
      localPlatform: 'HARMONY',
      localPublicKey: session.localPublicKey,
      remoteDeviceId: session.remoteDeviceId,
      verificationCode: '',
      reason: '',
      sentAt: Date.now()
    };
    return message;
  }

  static createAccept(session: LanPairingSession, localDeviceName: string): LanPairingMessage {
    const message: LanPairingMessage = {
      protocol: LanProtocolNames.PAIRING,
      kind: 'PAIR_ACCEPT',
      sessionId: session.id,
      localDeviceId: session.localDeviceId,
      localDeviceName: localDeviceName,
      localPlatform: 'HARMONY',
      localPublicKey: session.localPublicKey,
      remoteDeviceId: session.remoteDeviceId,
      verificationCode: session.verificationCode,
      reason: '',
      sentAt: Date.now()
    };
    return message;
  }

  static createReject(session: LanPairingSession, localDeviceName: string, reason: string): LanPairingMessage {
    const message: LanPairingMessage = {
      protocol: LanProtocolNames.PAIRING,
      kind: 'PAIR_REJECT',
      sessionId: session.id,
      localDeviceId: session.localDeviceId,
      localDeviceName: localDeviceName,
      localPlatform: 'HARMONY',
      localPublicKey: session.localPublicKey,
      remoteDeviceId: session.remoteDeviceId,
      verificationCode: '',
      reason: reason,
      sentAt: Date.now()
    };
    return message;
  }

  static encode(message: LanPairingMessage): string {
    return JSON.stringify(message);
  }

  static parse(text: string): LanPairingMessage | undefined {
    try {
      const message = JSON.parse(text) as LanPairingMessage;
      if (message.protocol !== LanProtocolNames.PAIRING) {
        return undefined;
      }
      if (message.kind !== 'PAIR_REQUEST' && message.kind !== 'PAIR_ACCEPT' && message.kind !== 'PAIR_REJECT') {
        return undefined;
      }
      if (message.sessionId.length === 0 || message.localDeviceId.length === 0) {
        return undefined;
      }
      return message;
    } catch (error) {
      console.error(`[CourseDrop] parse lan pairing protocol failed: ${String(error)}`);
      return undefined;
    }
  }
}
