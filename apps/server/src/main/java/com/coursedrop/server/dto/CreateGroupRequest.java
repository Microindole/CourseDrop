package com.coursedrop.server.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateGroupRequest(
        @NotBlank String encryptedName,
        @NotBlank String nameIv,
        @NotBlank String nameAuthTag,
        @NotBlank String creatorId,
        @NotBlank String configJson
) {
}
