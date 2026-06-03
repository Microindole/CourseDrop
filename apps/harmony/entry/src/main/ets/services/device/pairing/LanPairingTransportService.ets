import socket from '@ohos.net.socket';
import {
  LanPairingMessage,
  LanPairingProtocol
} from '../protocol/LanProtocolModels';
import { LanPairingService } from './LanPairingService';

interface UdpAddress {
  address: string;
  family: number;
  port: number;
}

interface UdpSendOptions {
  data: string;
  address: UdpAddress;
}

interface UdpRemoteInfo {
  address: string;
  port: number;
}

interface UdpMessage {
  message: ArrayBuffer;
  remoteInfo: UdpRemoteInfo;
}

export interface LanPairingTransportService {
  start(): Promise<void>;
  stop(): void;
  send(message: LanPairingMessage, remoteAddress: string): Promise<void>;
}

export class DefaultLanPairingTransportService implements LanPairingTransportService {
  private pairingService: LanPairingService;
  private readonly pairingPort: number = 39092;
  private localDeviceId: string;
  private localPublicKey: string;
  private localDeviceName: string;
  private udp?: socket.UDPSocket;

  constructor(
    pairingService: LanPairingService,
    localDeviceId: string,
    localPublicKey: string,
    localDeviceName: string
  ) {
    this.pairingService = pairingService;
    this.localDeviceId = localDeviceId;
    this.localPublicKey = localPublicKey;
    this.localDeviceName = localDeviceName;
  }

  async start(): Promise<void> {
    if (this.udp !== undefined) {
      return;
    }
    const udp = socket.constructUDPSocketInstance();
    const bindAddress: UdpAddress = {
      address: '0.0.0.0',
      family: 1,
      port: this.pairingPort
    };
    await udp.bind(bindAddress);
    udp.on('message', (message: UdpMessage) => {
      this.handleMessage(udp, message.message, message.remoteInfo);
    });
    this.udp = udp;
  }

  stop(): void {
    const udp = this.udp;
    if (udp === undefined) {
      return;
    }
    try {
      udp.off('message');
      udp.close();
    } catch (error) {
      console.error(`[CourseDrop] stop lan pairing transport failed: ${String(error)}`);
    }
    this.udp = undefined;
  }

  async send(message: LanPairingMessage, remoteAddress: string): Promise<void> {
    await this.start();
    const udp = this.udp;
    if (udp === undefined) {
      return;
    }
    const target = this.parseRemoteAddress(remoteAddress);
    const options: UdpSendOptions = {
      data: LanPairingProtocol.encode(message),
      address: {
        address: target.address,
        family: 1,
        port: target.port
      }
    };
    await udp.send(options);
  }

  private handleMessage(udp: socket.UDPSocket, buffer: ArrayBuffer, remoteInfo: UdpRemoteInfo): void {
    const text = this.decodeUtf8(buffer).trim();
    if (text.length === 0 || !text.startsWith('{')) {
      return;
    }
    const message = LanPairingProtocol.parse(text);
    if (message === undefined) {
      return;
    }
    if (message.localDeviceId === this.localDeviceId) {
      return;
    }
    const session = this.pairingService.handlePairingMessage(
      message,
      `${remoteInfo.address}:${remoteInfo.port}`,
      this.localDeviceId,
      this.localPublicKey
    );
    if (message.kind !== 'PAIR_REQUEST' || session === undefined) {
      return;
    }
    const accept = this.pairingService.createAcceptMessage(session.id, this.localDeviceName);
    if (accept === undefined) {
      return;
    }
    const options: UdpSendOptions = {
      data: LanPairingProtocol.encode(accept),
      address: {
        address: remoteInfo.address,
        family: 1,
        port: remoteInfo.port
      }
    };
    udp.send(options).catch((error: Error) => {
      console.error(`[CourseDrop] lan pairing accept failed: ${String(error)}`);
    });
  }

  private parseRemoteAddress(remoteAddress: string): UdpAddress {
    const withoutScheme = remoteAddress.replace('http://', '').replace('https://', '');
    const parts = withoutScheme.split(':');
    const address = parts.length > 0 && parts[0].length > 0 ? parts[0] : '127.0.0.1';
    let port = this.pairingPort;
    if (parts.length > 1) {
      const parsed = Number(parts[1]);
      if (parsed === parsed && parsed > 0) {
        port = parsed;
      }
    }
    return {
      address: address,
      family: 1,
      port: port
    };
  }

  private decodeUtf8(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let text = '';
    for (let index = 0; index < bytes.length; index += 1) {
      text += String.fromCharCode(bytes[index]);
    }
    return text;
  }
}
