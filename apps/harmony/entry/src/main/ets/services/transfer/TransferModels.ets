export interface RelayUploadRequest {
  shareId: string;
  localUri: string;
  displayName: string;
  contentType: string;
  encrypted: boolean;
  sha256?: string;
  encryptionAlgorithm?: string;
  kdfAlgorithm?: string;
  kdfSalt?: string;
  nonce?: string;
  plainSizeBytes?: number;
}

export interface RelayUploadResponse {
  id: string;
  shareId: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
  encrypted: boolean;
  expiresAt?: string;
}

export interface RelayDownloadRequest {
  code: string;
  itemId: string;
  targetDirectory: string;
  fingerprintId?: string;
  accountId?: string;
}

export interface RelayDownloadResult {
  localUri: string;
  displayName: string;
  sizeBytes: number;
  contentType: string;
}
