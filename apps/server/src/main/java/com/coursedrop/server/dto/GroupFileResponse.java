package com.coursedrop.server.dto;

import java.time.Instant;

public record GroupFileResponse(
        String id,
        String groupId,
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
