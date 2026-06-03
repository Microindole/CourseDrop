package com.coursedrop.server.dto;

import java.time.Instant;

import com.coursedrop.server.enums.GroupStatus;

public record GroupResponse(
        String id,
        String encryptedName,
        String nameIv,
        String nameAuthTag,
        String creatorId,
        GroupStatus status,
        String configJson,
        Instant createdAt
) {
}
