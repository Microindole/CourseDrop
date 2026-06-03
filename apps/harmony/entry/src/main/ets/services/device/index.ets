import { PreferencesDeviceRegistry } from './discovery/DeviceRegistry';
import { DeviceDiscoveryService } from './discovery/DeviceDiscoveryService';
import { LanDeviceDiscoveryService } from './discovery/LanDeviceDiscoveryService';
import { PreferencesLanPairingRepository } from './pairing/LanPairingRepository';
import { PreferencesTrustedDeviceRepository } from './pairing/TrustedDeviceRepository';
import { DefaultLanPairingService } from './pairing/LanPairingService';
import { DefaultLanPairingTransportService } from './pairing/LanPairingTransportService';
import { DefaultLanSecureChannelService } from './secure/LanSecureChannelService';

export type { DeviceDiscoveryService } from './discovery/DeviceDiscoveryService';
export type { DeviceRegistry } from './discovery/DeviceRegistry';
export { RuntimeDeviceRegistry, PreferencesDeviceRegistry } from './discovery/DeviceRegistry';
export { LanDeviceDiscoveryService } from './discovery/LanDeviceDiscoveryService';
export {
  LanProtocolNames,
  LanDiscoveryProtocol,
  LanPairingProtocol,
  LanPairingFactory
} from './protocol/LanProtocolModels';
export type {
  LanDiscoveryPayload,
  LanDiscoveryKind,
  LanPairingMessage,
  LanPairingMessageKind,
  LanPairingRole,
  LanPairingSession,
  LanPairingStatus,
  LanSecureChannelStatus,
  LanSecureSession,
  TrustedDevice
} from './protocol/LanProtocolModels';
export type { LanPairingRepository } from './pairing/LanPairingRepository';
export { PreferencesLanPairingRepository } from './pairing/LanPairingRepository';
export type { TrustedDeviceRepository } from './pairing/TrustedDeviceRepository';
export { PreferencesTrustedDeviceRepository } from './pairing/TrustedDeviceRepository';
export type { LanPairingService } from './pairing/LanPairingService';
export { DefaultLanPairingService } from './pairing/LanPairingService';
export type { LanPairingTransportService } from './pairing/LanPairingTransportService';
export { DefaultLanPairingTransportService } from './pairing/LanPairingTransportService';
export type { LanSecureChannelService } from './secure/LanSecureChannelService';
export { DefaultLanSecureChannelService } from './secure/LanSecureChannelService';

export const deviceDiscoveryService: DeviceDiscoveryService = new LanDeviceDiscoveryService(
  new PreferencesDeviceRegistry()
);
export const trustedDeviceRepository = new PreferencesTrustedDeviceRepository();
export const lanPairingService = new DefaultLanPairingService(
  new PreferencesLanPairingRepository(),
  trustedDeviceRepository
);
export const lanPairingTransportService = new DefaultLanPairingTransportService(
  lanPairingService,
  deviceDiscoveryService.getLocalDeviceId(),
  deviceDiscoveryService.getLocalPublicKey(),
  'CourseDrop Harmony'
);
export const lanSecureChannelService = new DefaultLanSecureChannelService();
