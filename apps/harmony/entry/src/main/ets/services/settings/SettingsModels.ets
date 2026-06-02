export type CachePolicy = 'MANUAL' | 'DAILY' | 'EXPIRED_ONLY';

export interface AppSettings {
  e2eeEnabled: boolean;
  lanFirstEnabled: boolean;
  defaultExpireHours: string;
  cachePolicy: CachePolicy;
}

export class DefaultAppSettings {
  static create(): AppSettings {
    return {
      e2eeEnabled: true,
      lanFirstEnabled: true,
      defaultExpireHours: '24',
      cachePolicy: 'EXPIRED_ONLY'
    };
  }
}
