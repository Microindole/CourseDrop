package com.coursedrop.server.group;

import java.time.Instant;

import com.coursedrop.server.enums.GroupMemberRole;
import com.coursedrop.server.enums.GroupMemberStatus;

public record GroupMemberRecord(
        String groupId,
        String fingerprintId,
        GroupMemberRole role,
        GroupMemberStatus status,
        Instant joinedAt,
        Instant leftAt
) {
}
