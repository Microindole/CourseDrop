import http from '@ohos.net.http';
import { Device } from '../models/Device';
import {
  deviceDiscoveryService,
  lanPairingService,
  LanPairingSession,
  TrustedDevice
} from '../services/device';

export class DeviceViewModel {
  scanning: boolean = false;
  devices: Device[] = deviceDiscoveryService.listDevices();
  pairingSessions: LanPairingSession[] = lanPairingService.listSessions();
  trustedDevices: TrustedDevice[] = lanPairingService.listTrustedDevices();
  errorMessage: string = '';
  lastActionText: string = '';

  getOnlineDevices(): Device[] {
    return this.devices.filter((device: Device) => device.status !== 'OFFLINE');
  }

  getLanDevices(): Device[] {
    return this.devices.filter((device: Device) => device.networkMode === 'LAN');
  }

  async refreshDevices(): Promise<void> {
    this.scanning = true;
    this.errorMessage = '';
    try {
      this.devices = await deviceDiscoveryService.refresh();
      this.lastActionText = this.devices.length > 0 ? '局域网发现完成' : '未发现同局域网节点';
    } catch (error) {
      this.errorMessage = `局域网发现失败：${String(error)}`;
      this.lastActionText = '局域网发现失败';
    } finally {
      this.scanning = false;
    }
  }

  async startLanResponder(): Promise<void> {
    try {
      await deviceDiscoveryService.startLanResponder();
      this.lastActionText = '局域网设备监听已开启';
      this.errorMessage = '';
    } catch (error) {
      this.lastActionText = '局域网监听失败';
      this.errorMessage = String(error);
    }
  }

  stopLanResponder(): void {
    deviceDiscoveryService.stopLanResponder();
  }

  startPairing(device: Device): LanPairingSession | undefined {
    if (device.status === 'OFFLINE') {
      this.lastActionText = `${device.name} 当前离线`;
      this.errorMessage = '请先刷新或测试连接后再发起配对';
      return undefined;
    }
    const session = lanPairingService.startPairing(
      device,
      deviceDiscoveryService.getLocalDeviceId(),
      deviceDiscoveryService.getLocalPublicKey()
    );
    this.refreshPairingState();
    this.lastActionText = `请在两台设备上核对验证码 ${session.verificationCode}`;
    this.errorMessage = '';
    return session;
  }

  confirmPairing(sessionId: string): void {
    const trusted = lanPairingService.confirmPairing(sessionId);
    this.refreshPairingState();
    if (trusted === undefined) {
      this.lastActionText = '配对会话不存在';
      this.errorMessage = '请重新扫描设备后再配对';
      return;
    }
    this.lastActionText = `已信任 ${trusted.name}`;
    this.errorMessage = '';
  }

  rejectPairing(sessionId: string): void {
    lanPairingService.rejectPairing(sessionId);
    this.refreshPairingState();
    this.lastActionText = '已拒绝本次配对';
    this.errorMessage = '';
  }

  addDebugLanDevice(): void {
    const device: Device = {
      id: 'debug-pc-mock-001',
      name: 'PC Mock Device',
      platform: 'WINDOWS',
      status: 'ONLINE',
      networkMode: 'LAN',
      latencyMs: 1,
      address: '127.0.0.1:39092',
      lastSeenAt: new Date().toISOString()
    };
    deviceDiscoveryService.saveManualDevice(device);
    this.devices = deviceDiscoveryService.listDevices();
    this.lastActionText = '已添加调试局域网设备';
    this.errorMessage = '';
  }

  beginManualProbe(): void {
    this.scanning = true;
    this.lastActionText = '正在测试设备连接...';
    this.errorMessage = '';
  }

  async addManualDevice(name: string, address: string): Promise<void> {
    const normalizedAddress = this.normalizeAddress(address);
    if (normalizedAddress.length === 0) {
      this.scanning = false;
      this.lastActionText = '请输入电脑或服务器地址';
      this.errorMessage = '示例：http://192.168.1.10:9090';
      return;
    }
    this.scanning = true;
    this.errorMessage = '';
    try {
      const probe = await this.probeAddress(normalizedAddress);
      const deviceName = name.trim().length > 0 ? name.trim() : probe.name;
      const device: Device = {
        id: this.deviceIdFromAddress(normalizedAddress),
        name: deviceName,
        platform: probe.platform,
        status: probe.ok ? 'ONLINE' : 'OFFLINE',
        networkMode: 'LAN',
        latencyMs: probe.latencyMs,
        address: normalizedAddress,
        lastSeenAt: new Date().toISOString()
      };
      deviceDiscoveryService.saveManualDevice(device);
      this.devices = deviceDiscoveryService.listDevices();
      this.lastActionText = probe.ok ? `已连接 ${deviceName}` : `已保存 ${deviceName}，但当前不可达`;
      this.errorMessage = probe.ok ? '' : probe.message;
    } catch (error) {
      this.lastActionText = '手动连接失败';
      this.errorMessage = String(error);
    } finally {
      this.scanning = false;
    }
  }

  async probeDevice(device: Device): Promise<void> {
    if (device.address === undefined || device.address.length === 0) {
      this.lastActionText = `${device.name} 缺少连接地址`;
      this.errorMessage = '请重新手动添加设备地址';
      return;
    }
    this.scanning = true;
    this.errorMessage = '';
    try {
      const probe = await this.probeAddress(device.address);
      const updated: Device = {
        id: device.id,
        name: device.name,
        platform: probe.platform,
        status: probe.ok ? 'ONLINE' : 'OFFLINE',
        networkMode: 'LAN',
        latencyMs: probe.latencyMs,
        address: device.address,
        lastSeenAt: new Date().toISOString()
      };
      deviceDiscoveryService.saveManualDevice(updated);
      this.devices = deviceDiscoveryService.listDevices();
      this.lastActionText = probe.ok ? `${device.name} 连接正常 · ${probe.latencyMs} ms` : `${device.name} 不可达`;
      this.errorMessage = probe.ok ? '' : probe.message;
    } catch (error) {
      this.lastActionText = `${device.name} 探测失败`;
      this.errorMessage = String(error);
    } finally {
      this.scanning = false;
    }
  }

  private refreshPairingState(): void {
    this.pairingSessions = lanPairingService.listSessions();
    this.trustedDevices = lanPairingService.listTrustedDevices();
  }

  private normalizeAddress(address: string): string {
    const trimmed = address.trim().replace(/\/$/, '');
    if (trimmed.length === 0) {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return `http://${trimmed}`;
  }

  private deviceIdFromAddress(address: string): string {
    return `manual-${address.replace(/[^a-zA-Z0-9]/g, '-')}`;
  }

  private async probeAddress(baseUrl: string): Promise<DeviceProbeResult> {
    const request = http.createHttp();
    const startedAt = Date.now();
    try {
      const response = await request.request(`${baseUrl}/api/health`, {
        method: http.RequestMethod.GET,
        connectTimeout: 3000,
        readTimeout: 3000
      });
      const latencyMs = Date.now() - startedAt;
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return {
          ok: false,
          message: `HTTP ${response.responseCode}`,
          name: 'CourseDrop 设备',
          platform: 'UNKNOWN',
          latencyMs: latencyMs
        };
      }
      const health = JSON.parse(String(response.result)) as DeviceHealthResponse;
      return {
        ok: health.status === 'UP',
        message: health.status === 'UP' ? '连接正常' : '服务状态异常',
        name: health.service.length > 0 ? health.service : 'CourseDrop 设备',
        platform: 'WEB',
        latencyMs: latencyMs
      };
    } finally {
      request.destroy();
    }
  }
}

interface DeviceHealthResponse {
  status: string;
  service: string;
  time: string;
}

interface DeviceProbeResult {
  ok: boolean;
  message: string;
  name: string;
  platform: 'WEB' | 'UNKNOWN';
  latencyMs: number;
}
