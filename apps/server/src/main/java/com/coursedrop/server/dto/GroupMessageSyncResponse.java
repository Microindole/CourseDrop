package com.coursedrop.server.dto;

import java.util.List;

public record GroupMessageSyncResponse(
        List<GroupMessageResponse> messages,
        String nextCursor
) {
}
