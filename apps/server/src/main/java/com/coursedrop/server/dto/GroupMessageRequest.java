package com.coursedrop.server.dto;

import com.coursedrop.server.enums.GroupMessageType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record GroupMessageRequest(
        @NotBlank String id,
        @NotBlank String senderId,
        @NotNull GroupMessageType type,
        @NotBlank String iv,
        @NotBlank String authTag,
        @NotBlank String encryptedPayload
) {
}
