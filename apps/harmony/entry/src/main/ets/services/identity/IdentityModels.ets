export interface DeviceFingerprintResponse {
  id: string;
  fingerprint: string;
  deviceName: string;
  platform: string;
  accountId: string | null;
  createdAt: string;
  lastSeenAt: string;
}

export interface LocalIdentity {
  fingerprint: string;
  fingerprintId: string;
  deviceName: string;
  accountId: string;
  accountUsername?: string;
}

export interface AccountResponse {
  id: string;
  username: string;
  passwordLoginEnabled: boolean;
  createdAt: string;
}
