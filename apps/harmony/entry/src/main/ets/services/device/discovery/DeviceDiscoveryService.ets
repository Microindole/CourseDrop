import { Device } from '../../../models/Device';

export interface DeviceDiscoveryService {
  listDevices(): Device[];
  refresh(): Promise<Device[]>;
  saveManualDevice(device: Device): void;
  startLanResponder(): Promise<void>;
  stopLanResponder(): void;
  getLocalDeviceId(): string;
  getLocalPublicKey(): string;
}
