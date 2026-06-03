import { DevicePlatform } from '../../../models/Device';

export class LanProtocolNames {
  static readonly DISCOVERY: string = 'coursedrop.discovery.v1';
  static readonly PAIRING: string = 'coursedrop.pairing.v1';
  static readonly SECURE: string = 'coursedrop.secure.v1';
}

export type LanDiscoveryKind = 'DISCOVER' | 'ANNOUNCE';
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

  private static verificationCode(
    localDeviceId: string,
    remoteDeviceId: string,
    localPublicKey: string,
    remotePublicKey: string
  ): string {
    const material = `${localDeviceId}|${remoteDeviceId}|${localPublicKey}|${remotePublicKey}`;
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
