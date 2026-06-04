import webSocket from '@ohos.net.webSocket';
import { ApiClient } from '../ApiClient';
import { identityService } from '../identity';

export interface GroupRealtimeMessage {
  id: string;
  groupId: string;
  senderId: string;
  type: string;
  iv: string;
  authTag: string;
  encryptedPayload: string;
  createdAt: string;
}

export interface GroupRealtimeEvent {
  type: string;
  groupId: string;
  payload: GroupRealtimeMessage;
}

export type GroupRealtimeListener = (event: GroupRealtimeEvent) => void;

export interface GroupRealtimeService {
  connect(): void;
  disconnect(): void;
  subscribe(listener: GroupRealtimeListener): () => void;
}

export class DefaultGroupRealtimeService implements GroupRealtimeService {
  private apiClient: ApiClient;
  private socket?: webSocket.WebSocket;
  private listeners: GroupRealtimeListener[] = [];
  private connected: boolean = false;
  private connecting: boolean = false;
  private manuallyClosed: boolean = false;
  private reconnectDelayMs: number = 1000;
  private reconnectTimer?: number;

  constructor(apiClient: ApiClient) {
    this.apiClient = apiClient;
  }

  connect(): void {
    if (this.connected || this.connecting) {
      return;
    }
    this.manuallyClosed = false;
    this.clearReconnectTimer();
    const identity = identityService.getLocalIdentity();
    if (identity === undefined || identity.fingerprintId.length === 0 || !this.apiClient.hasBaseUrl()) {
      return;
    }
    const url = this.buildWebSocketUrl(identity.fingerprintId);
    const socket = webSocket.createWebSocket();
    this.socket = socket;
    this.connecting = true;

    socket.on('open', (_error: Error, _value: Object) => {
      this.connected = true;
      this.connecting = false;
      this.reconnectDelayMs = 1000;
      console.info('[CourseDrop] group realtime connected');
    });
    socket.on('message', (_error: Error, value: string | ArrayBuffer) => {
      this.handleMessage(value);
    });
    socket.on('close', (_error: Error, _value: Object) => {
      this.connected = false;
      this.connecting = false;
      console.info('[CourseDrop] group realtime closed');
      this.scheduleReconnect();
    });
    socket.on('error', (error: Error) => {
      this.connected = false;
      this.connecting = false;
      console.error(`[CourseDrop] group realtime failed: ${String(error)}`);
      this.scheduleReconnect();
    });
    socket.connect(url, (error: Error) => {
      if (error) {
        this.connected = false;
        this.connecting = false;
        console.error(`[CourseDrop] group realtime connect failed: ${String(error)}`);
        this.scheduleReconnect();
      }
    });
  }

  disconnect(): void {
    this.manuallyClosed = true;
    this.clearReconnectTimer();
    if (this.socket === undefined) {
      return;
    }
    try {
      this.socket.close();
    } catch (error) {
      console.error(`[CourseDrop] group realtime close failed: ${String(error)}`);
    }
    this.socket = undefined;
    this.connected = false;
    this.connecting = false;
  }

  subscribe(listener: GroupRealtimeListener): () => void {
    this.listeners.push(listener);
    this.connect();
    return () => {
      this.listeners = this.listeners.filter((next: GroupRealtimeListener) => next !== listener);
    };
  }

  private scheduleReconnect(): void {
    if (this.manuallyClosed || this.reconnectTimer !== undefined) {
      return;
    }
    const delayMs = this.reconnectDelayMs;
    this.reconnectDelayMs = Math.min(this.reconnectDelayMs * 2, 30000);
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = undefined;
      this.socket = undefined;
      this.connect();
    }, delayMs);
  }

  private clearReconnectTimer(): void {
    if (this.reconnectTimer === undefined) {
      return;
    }
    clearTimeout(this.reconnectTimer);
    this.reconnectTimer = undefined;
  }

  private handleMessage(value: string | ArrayBuffer): void {
    const text = typeof value === 'string' ? value : this.decodeUtf8(value);
    if (text.length === 0 || text === 'pong') {
      return;
    }
    try {
      const event = JSON.parse(text) as GroupRealtimeEvent;
      if (event.type !== 'GROUP_MESSAGE_CREATED' || event.groupId.length === 0) {
        return;
      }
      this.listeners.forEach((listener: GroupRealtimeListener) => {
        listener(event);
      });
    } catch (error) {
      console.error(`[CourseDrop] parse group realtime event failed: ${String(error)}`);
    }
  }

  private buildWebSocketUrl(fingerprintId: string): string {
    const baseUrl = this.apiClient.getBaseUrl();
    let wsBaseUrl = baseUrl;
    if (wsBaseUrl.startsWith('https://')) {
      wsBaseUrl = `wss://${wsBaseUrl.substring('https://'.length)}`;
    } else if (wsBaseUrl.startsWith('http://')) {
      wsBaseUrl = `ws://${wsBaseUrl.substring('http://'.length)}`;
    }
    return `${wsBaseUrl}/ws/groups?fingerprintId=${encodeURIComponent(fingerprintId)}`;
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
