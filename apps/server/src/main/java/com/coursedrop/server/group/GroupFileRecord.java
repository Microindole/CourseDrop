package com.coursedrop.server.group;

import java.time.Instant;

public record GroupFileRecord(
        String id,
        String groupId,
        String uploaderId,
        String storageKey,
        String contentType,
        long sizeBytes,
        boolean encrypted,
        String encryptionAlgorithm,
        String kdfAlgorithm,
        String kdfSalt,
        String nonce,
        String sha256,
        Long plainSizeBytes,
        Instant createdAt,
        Instant expiresAt
) {
}
