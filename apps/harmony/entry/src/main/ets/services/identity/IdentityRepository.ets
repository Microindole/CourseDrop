import { appPreferencesStore } from '../../common/AppPreferencesStore';
import { LocalIdentity } from './IdentityModels';

const KEY_LOCAL_IDENTITY: string = 'identity.local';

export interface IdentityRepository {
  get(): LocalIdentity | undefined;
  save(identity: LocalIdentity): void;
}

export class LocalIdentityRepository implements IdentityRepository {
  private identity?: LocalIdentity;

  get(): LocalIdentity | undefined {
    return this.identity;
  }

  save(identity: LocalIdentity): void {
    this.identity = identity;
  }
}

export class PreferencesIdentityRepository implements IdentityRepository {
  private identity?: LocalIdentity;
  private loaded: boolean = false;

  get(): LocalIdentity | undefined {
    this.ensureLoaded();
    if (this.identity === undefined) {
      return undefined;
    }
    return this.copyIdentity(this.identity);
  }

  save(identity: LocalIdentity): void {
    this.identity = this.copyIdentity(identity);
    appPreferencesStore.putString(KEY_LOCAL_IDENTITY, JSON.stringify(this.identity));
  }

  private ensureLoaded(): void {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const jsonText = appPreferencesStore.getString(KEY_LOCAL_IDENTITY, '');
    if (jsonText.length === 0) {
      return;
    }
    try {
      const identity = JSON.parse(jsonText) as LocalIdentity;
      this.identity = this.copyIdentity(identity);
    } catch (error) {
      console.error(`[CourseDrop] load identity failed: ${String(error)}`);
      this.identity = undefined;
    }
  }

  private copyIdentity(identity: LocalIdentity): LocalIdentity {
    return {
      fingerprint: identity.fingerprint,
      fingerprintId: identity.fingerprintId,
      deviceName: identity.deviceName,
      accountId: identity.accountId,
      accountUsername: identity.accountUsername
    };
  }
}
