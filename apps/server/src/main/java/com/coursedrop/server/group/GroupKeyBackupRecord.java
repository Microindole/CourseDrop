package com.coursedrop.server.group;

import java.time.Instant;

public record GroupKeyBackupRecord(
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
