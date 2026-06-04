package com.coursedrop.server.dto;

public record GroupMembershipResponse(
        GroupResponse group,
        GroupMemberResponse member) {
}
