import { Device } from '../../../models/Device';
import { appPreferencesStore } from '../../../common/AppPreferencesStore';

const KEY_DEVICES: string = 'device.registry';

export interface DeviceRegistry {
  list(): Device[];
  save(device: Device): void;
}

export class RuntimeDeviceRegistry implements DeviceRegistry {
  private devices: Device[] = [];

  list(): Device[] {
    return this.devices;
  }

  save(device: Device): void {
    const index = this.devices.findIndex((next: Device) => next.id === device.id);
    if (index < 0) {
      this.devices.push(device);
      return;
    }
    this.devices[index] = device;
  }
}

export class PreferencesDeviceRegistry implements DeviceRegistry {
  private devices: Device[] = [];
  private loaded: boolean = false;

  list(): Device[] {
    this.ensureLoaded();
    return this.devices.map((device: Device) => this.copyDevice(device));
  }

  save(device: Device): void {
    this.ensureLoaded();
    const copy = this.copyDevice(device);
    const index = this.devices.findIndex((next: Device) => next.id === copy.id);
    if (index < 0) {
      this.devices.push(copy);
    } else {
      this.devices[index] = copy;
    }
    this.persist();
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_DEVICES, '');
    if (jsonText.length === 0) {
      return;
    }
    try {
      const loadedDevices = JSON.parse(jsonText) as Device[];
      this.devices = loadedDevices.map((device: Device) => this.copyDevice(device));
    } catch (error) {
      console.error(`[CourseDrop] load devices failed: ${String(error)}`);
      this.devices = [];
    }
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_DEVICES, JSON.stringify(this.devices));
  }

  private copyDevice(device: Device): Device {
    return {
      id: device.id,
      name: device.name,
      platform: device.platform,
      status: device.status,
      networkMode: device.networkMode,
      latencyMs: device.latencyMs,
      address: device.address,
      lastSeenAt: device.lastSeenAt
    };
  }
}
