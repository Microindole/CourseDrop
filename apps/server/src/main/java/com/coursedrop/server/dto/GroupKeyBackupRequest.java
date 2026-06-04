package com.coursedrop.server.dto;

import jakarta.validation.constraints.NotBlank;

public record GroupKeyBackupRequest(
        @NotBlank String algorithm,
        @NotBlank String kdfAlgorithm,
        String kdfSalt,
        @NotBlank String iv,
        @NotBlank String authTag,
        @NotBlank String encryptedPayload
) {
}
