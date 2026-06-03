package com.coursedrop.server.dto;

import java.time.Instant;

import com.coursedrop.server.enums.GroupMemberRole;
import com.coursedrop.server.enums.GroupMemberStatus;

public record GroupMemberResponse(
        String groupId,
        String fingerprintId,
        GroupMemberRole role,
        GroupMemberStatus status,
        Instant joinedAt,
        Instant leftAt
) {
}
