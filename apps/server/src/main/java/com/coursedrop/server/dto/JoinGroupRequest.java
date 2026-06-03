package com.coursedrop.server.dto;

import jakarta.validation.constraints.NotBlank;

public record JoinGroupRequest(
        @NotBlank String fingerprintId
) {
}
