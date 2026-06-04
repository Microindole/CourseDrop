package com.coursedrop.server.dto;

import java.time.Instant;

public record GroupKeyBackupResponse(
        String id,
        String accountId,
        String fingerprintId,
        String groupId,
        String algorithm,
        String kdfAlgorithm,
        String kdfSalt,
        String iv,
        String authTag,
        String encryptedPayload,
        Instant createdAt,
        Instant updatedAt
) {
}
