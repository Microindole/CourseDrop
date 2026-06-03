import socket from '@ohos.net.socket';
import { Device } from '../../../models/Device';
import { appPreferencesStore } from '../../../common/AppPreferencesStore';
import { DeviceDiscoveryService } from './DeviceDiscoveryService';
import { DeviceRegistry } from './DeviceRegistry';
import { LanDiscoveryPayload, LanDiscoveryProtocol } from '../protocol/LanProtocolModels';

const KEY_LAN_DEVICE_ID: string = 'lan.deviceId';
const KEY_LAN_PUBLIC_KEY: string = 'lan.publicKey';

interface UdpAddress {
  address: string;
  family: number;
  port: number;
}

interface UdpSendOptions {
  data: string;
  address: UdpAddress;
}

interface UdpExtraOptions {
  broadcast: boolean;
}

interface UdpRemoteInfo {
  address: string;
  port: number;
}

interface UdpMessage {
  message: ArrayBuffer;
  remoteInfo: UdpRemoteInfo;
}

export class LanDeviceDiscoveryService implements DeviceDiscoveryService {
  private registry: DeviceRegistry;
  private readonly discoveryPort: number = 39091;
  private readonly pairingPort: number = 39092;
  private readonly transferPort: number = 39092;
  private responderSocket?: socket.UDPSocket;
  private localDeviceId: string = this.loadLocalDeviceId();
  private localPublicKey: string = this.loadLocalPublicKey();

  constructor(registry: DeviceRegistry) {
    this.registry = registry;
  }

  listDevices(): Device[] {
    return this.registry.list();
  }

  async refresh(): Promise<Device[]> {
    await this.startLanResponder();
    const udp = this.responderSocket;
    if (udp === undefined) {
      return this.registry.list();
    }
    const options: UdpSendOptions = {
      data: this.buildDiscoveryPayload('DISCOVER'),
      address: {
        address: '255.255.255.255',
        family: 1,
        port: this.discoveryPort
      }
    };
    await udp.send(options);
    await this.sleep(1200);
    return this.registry.list();
  }

  saveManualDevice(device: Device): void {
    this.registry.save(device);
  }

  async startLanResponder(): Promise<void> {
    if (this.responderSocket !== undefined) {
      return;
    }
    const udp = socket.constructUDPSocketInstance();
    const bindAddress: UdpAddress = {
      address: '0.0.0.0',
      family: 1,
      port: this.discoveryPort
    };
    await udp.bind(bindAddress);
    const extraOptions: UdpExtraOptions = {
      broadcast: true
    };
    await udp.setExtraOptions(extraOptions);
    udp.on('message', (message: UdpMessage) => {
      this.handleMessage(message.message, message.remoteInfo.address);
      this.replyToDiscovery(udp, message.message, message.remoteInfo);
    });
    this.responderSocket = udp;
  }

  stopLanResponder(): void {
    const udp = this.responderSocket;
    if (udp === undefined) {
      return;
    }
    try {
      udp.off('message');
      udp.close();
    } catch (error) {
      console.error(`[CourseDrop] stop lan responder failed: ${String(error)}`);
    }
    this.responderSocket = undefined;
  }

  getLocalDeviceId(): string {
    return this.localDeviceId;
  }

  getLocalPublicKey(): string {
    return this.localPublicKey;
  }

  private handleMessage(buffer: ArrayBuffer, address: string): void {
    const text = this.decodeUtf8(buffer).trim();
    if (text.length === 0 || !text.startsWith('{')) {
      return;
    }
    const payload = this.parsePayload(text);
    if (payload === undefined) {
      return;
    }
    if (payload.deviceId === this.localDeviceId) {
      return;
    }
    this.registry.save({
      id: payload.deviceId,
      name: payload.deviceName,
      platform: payload.platform,
      status: 'ONLINE',
      networkMode: 'LAN',
      latencyMs: payload.sentAt > 0 ? Math.max(Date.now() - payload.sentAt, 0) : 0,
      address: `${address}:${payload.pairingPort}`,
      lastSeenAt: new Date().toISOString()
    });
  }

  private replyToDiscovery(udp: socket.UDPSocket, buffer: ArrayBuffer, remoteInfo: UdpRemoteInfo): void {
    const text = this.decodeUtf8(buffer).trim();
    if (text.length === 0 || !text.startsWith('{')) {
      return;
    }
    const payload = this.parsePayload(text);
    if (payload === undefined) {
      return;
    }
    if (payload.deviceId === this.localDeviceId || payload.kind === 'ANNOUNCE') {
      return;
    }
    const options: UdpSendOptions = {
      data: this.buildDiscoveryPayload('ANNOUNCE'),
      address: {
        address: remoteInfo.address,
        family: 1,
        port: payload.responsePort > 0 ? payload.responsePort : remoteInfo.port
      }
    };
    udp.send(options).catch((error: Error) => {
      console.error(`[CourseDrop] lan discovery reply failed: ${String(error)}`);
    });
  }

  private buildDiscoveryPayload(kind: string): string {
    const payload = LanDiscoveryProtocol.createPayload(
      kind === 'ANNOUNCE' ? 'ANNOUNCE' : 'DISCOVER',
      this.localDeviceId,
      'CourseDrop Harmony',
      this.discoveryPort,
      this.pairingPort,
      this.transferPort,
      this.publicKeyFingerprint(this.localPublicKey)
    );
    return LanDiscoveryProtocol.encode(payload);
  }

  private loadLocalDeviceId(): string {
    const existing = appPreferencesStore.getString(KEY_LAN_DEVICE_ID, '');
    if (existing.length > 0) {
      return existing;
    }
    const created = `harmony-lan-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
    appPreferencesStore.putString(KEY_LAN_DEVICE_ID, created);
    return created;
  }

  private loadLocalPublicKey(): string {
    const existing = appPreferencesStore.getString(KEY_LAN_PUBLIC_KEY, '');
    if (existing.length > 0) {
      return existing;
    }
    const created = `lan-key-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
    appPreferencesStore.putString(KEY_LAN_PUBLIC_KEY, created);
    return created;
  }

  private publicKeyFingerprint(publicKey: string): string {
    let hash = 0;
    for (let index = 0; index < publicKey.length; index += 1) {
      hash = ((hash << 5) - hash + publicKey.charCodeAt(index)) | 0;
    }
    return Math.abs(hash).toString(16);
  }

  private parsePayload(text: string): LanDiscoveryPayload | undefined {
    return LanDiscoveryProtocol.parse(text);
  }

  private decodeUtf8(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let text = '';
    for (let index = 0; index < bytes.length; index += 1) {
      text += String.fromCharCode(bytes[index]);
    }
    return text;
  }

  private sleep(durationMs: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, durationMs);
    });
  }
}
