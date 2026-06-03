import { appPreferencesStore } from '../../../common/AppPreferencesStore';
import { TrustedDevice } from '../protocol/LanProtocolModels';

const KEY_TRUSTED_DEVICES: string = 'lan.trusted.devices';

export interface TrustedDeviceRepository {
  list(): TrustedDevice[];
  save(device: TrustedDevice): void;
  findById(id: string): TrustedDevice | undefined;
}

export class PreferencesTrustedDeviceRepository implements TrustedDeviceRepository {
  private devices: TrustedDevice[] = [];
  private loaded: boolean = false;

  list(): TrustedDevice[] {
    this.ensureLoaded();
    return this.devices.map((device: TrustedDevice) => this.copyDevice(device));
  }

  save(device: TrustedDevice): void {
    this.ensureLoaded();
    const copy = this.copyDevice(device);
    const index = this.devices.findIndex((next: TrustedDevice) => next.id === copy.id);
    if (index < 0) {
      this.devices.push(copy);
    } else {
      this.devices[index] = copy;
    }
    this.persist();
  }

  findById(id: string): TrustedDevice | undefined {
    this.ensureLoaded();
    const device = this.devices.find((next: TrustedDevice) => next.id === id);
    if (device === undefined) {
      return undefined;
    }
    return this.copyDevice(device);
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_TRUSTED_DEVICES, '');
    if (jsonText.length === 0) {
      return;
    }
    try {
      const loadedDevices = JSON.parse(jsonText) as TrustedDevice[];
      this.devices = loadedDevices.map((device: TrustedDevice) => this.copyDevice(device));
    } catch (error) {
      console.error(`[CourseDrop] load trusted devices failed: ${String(error)}`);
      this.devices = [];
    }
  }

  private persist(): void {
    appPreferencesStore.putString(KEY_TRUSTED_DEVICES, JSON.stringify(this.devices));
  }

  private copyDevice(device: TrustedDevice): TrustedDevice {
    return {
      id: device.id,
      name: device.name,
      platform: device.platform,
      publicKeyFingerprint: device.publicKeyFingerprint,
      lastAddress: device.lastAddress,
      trustedAt: device.trustedAt,
      lastSeenAt: device.lastSeenAt
    };
  }
}
