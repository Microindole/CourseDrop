package com.coursedrop.server.dto;

import java.time.Instant;

import com.coursedrop.server.enums.GroupMessageType;

public record GroupMessageResponse(
        String id,
        String groupId,
        String senderId,
        GroupMessageType type,
        String iv,
        String authTag,
        String encryptedPayload,
        Instant createdAt
) {
}
