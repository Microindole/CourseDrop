package com.coursedrop.server.group;

import java.time.Instant;

import com.coursedrop.server.enums.GroupMessageType;

public record GroupMessageRecord(
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
