import { ApiClient } from '../ApiClient';
import { AccountResponse, DeviceFingerprintResponse, LocalIdentity } from './IdentityModels';
import { IdentityRepository } from './IdentityRepository';

interface FingerprintHeader {
  'X-CourseDrop-Fingerprint-Id': string;
}

export class IdentityService {
  private apiClient: ApiClient;
  private repository: IdentityRepository;

  constructor(apiClient: ApiClient, repository: IdentityRepository) {
    this.apiClient = apiClient;
    this.repository = repository;
  }

  getLocalIdentity(): LocalIdentity | undefined {
    return this.repository.get();
  }

  async registerCurrentDevice(): Promise<LocalIdentity> {
    const existing = this.repository.get();
    const fingerprint = existing === undefined ? this.createFingerprint() : existing.fingerprint;
    const deviceName = existing === undefined ? 'HarmonyOS 设备' : existing.deviceName;
    const body = JSON.stringify({
      fingerprint: fingerprint,
      deviceName: deviceName,
      platform: 'HarmonyOS'
    });
    const responseText = await this.apiClient.postJson('/api/identity/fingerprints', body);
    const response = JSON.parse(responseText) as DeviceFingerprintResponse;
    const identity: LocalIdentity = {
      fingerprint: response.fingerprint,
      fingerprintId: response.id,
      deviceName: response.deviceName,
      accountId: response.accountId === null ? '' : response.accountId,
      accountUsername: existing === undefined ? undefined : existing.accountUsername
    };
    this.repository.save(identity);
    return identity;
  }

  async confirmWebLogin(loginCode: string): Promise<void> {
    const identity = this.repository.get();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    const body = JSON.stringify({
      fingerprintId: identity.fingerprintId
    });
    await this.apiClient.postJson(`/api/auth/web-login/${loginCode}/confirm`, body);
  }

  async createAccount(username: string, password: string, passwordLoginEnabled: boolean): Promise<AccountResponse> {
    const identity = this.repository.get();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    const body = JSON.stringify({
      username: username,
      password: password,
      fingerprintId: identity.fingerprintId,
      passwordLoginEnabled: passwordLoginEnabled
    });
    const responseText = await this.apiClient.postJson('/api/accounts', body);
    const response = JSON.parse(responseText) as AccountResponse;
    this.repository.save({
      fingerprint: identity.fingerprint,
      fingerprintId: identity.fingerprintId,
      deviceName: identity.deviceName,
      accountId: response.id,
      accountUsername: response.username
    });
    return response;
  }

  async loginAccount(username: string, password: string): Promise<AccountResponse> {
    const identity = this.repository.get();
    if (identity === undefined || identity.fingerprintId.length === 0) {
      throw new Error('请先注册本机身份');
    }
    const body = JSON.stringify({
      username: username,
      password: password,
      fingerprintId: identity.fingerprintId
    });
    const responseText = await this.apiClient.postJson('/api/accounts/login', body);
    const response = JSON.parse(responseText) as AccountResponse;
    this.repository.save({
      fingerprint: identity.fingerprint,
      fingerprintId: identity.fingerprintId,
      deviceName: identity.deviceName,
      accountId: response.id,
      accountUsername: response.username
    });
    return response;
  }

  async updateAccountSecurity(passwordLoginEnabled: boolean): Promise<AccountResponse> {
    const identity = this.repository.get();
    if (identity === undefined || identity.accountId.length === 0) {
      throw new Error('当前设备尚未绑定账号');
    }
    const body = JSON.stringify({
      passwordLoginEnabled: passwordLoginEnabled
    });
    const headers: FingerprintHeader = {
      'X-CourseDrop-Fingerprint-Id': identity.fingerprintId
    };
    const responseText = await this.apiClient.postJson(
      `/api/accounts/${identity.accountId}/security`,
      body,
      headers
    );
    return JSON.parse(responseText) as AccountResponse;
  }

  private createFingerprint(): string {
    return `harmony-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
  }
}
