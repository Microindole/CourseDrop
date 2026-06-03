package com.coursedrop.server.group;

import java.time.Instant;

import com.coursedrop.server.enums.GroupStatus;

public record GroupRecord(
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
