package com.coursedrop.server.group;

public record GroupRealtimeEvent(
        String type,
        String groupId,
        Object payload) {
}
