package com.coursedrop.server.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.coursedrop.server.dto.CreateGroupRequest;
import com.coursedrop.server.dto.GroupMemberResponse;
import com.coursedrop.server.dto.GroupMembershipResponse;
import com.coursedrop.server.dto.GroupKeyBackupRequest;
import com.coursedrop.server.dto.GroupKeyBackupResponse;
import com.coursedrop.server.dto.GroupMessageRequest;
import com.coursedrop.server.dto.GroupMessageResponse;
import com.coursedrop.server.dto.GroupMessageSyncResponse;
import com.coursedrop.server.dto.GroupResponse;
import com.coursedrop.server.dto.GroupFileResponse;
import com.coursedrop.server.dto.JoinGroupRequest;
import com.coursedrop.server.service.GroupService;

import jakarta.validation.Valid;
import java.util.List;

@Validated
@RestController
@RequestMapping("/api/groups")
public class GroupController {
    private final GroupService groupService;

    public GroupController(GroupService groupService) {
        this.groupService = groupService;
    }

    @PostMapping
    public GroupResponse create(@Valid @RequestBody CreateGroupRequest request) {
        return groupService.create(request);
    }

    @GetMapping("/{groupId}")
    public GroupResponse get(@PathVariable String groupId) {
        return groupService.get(groupId);
    }

    @GetMapping("/mine")
    public List<GroupMembershipResponse> mine(
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId) {
        return groupService.listMine(fingerprintId);
    }

    @PostMapping("/{groupId}/join")
    public GroupMemberResponse join(@PathVariable String groupId, @Valid @RequestBody JoinGroupRequest request) {
        return groupService.join(groupId, request.fingerprintId());
    }

    @DeleteMapping("/{groupId}/members/me")
    public ResponseEntity<Void> leave(
            @PathVariable String groupId,
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId) {
        groupService.leave(groupId, fingerprintId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{groupId}/members")
    public List<GroupMemberResponse> members(
            @PathVariable String groupId,
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId) {
        return groupService.listMembers(groupId, fingerprintId);
    }

    @PostMapping("/{groupId}/messages")
    public GroupMessageResponse sendMessage(
            @PathVariable String groupId,
            @Valid @RequestBody GroupMessageRequest request) {
        return groupService.sendMessage(groupId, request);
    }

    @GetMapping("/{groupId}/messages")
    public GroupMessageSyncResponse syncMessages(
            @PathVariable String groupId,
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId,
            @RequestParam(required = false) String after) {
        return groupService.syncMessages(groupId, fingerprintId, after);
    }

    @PostMapping("/{groupId}/files")
    public GroupFileResponse uploadFile(
            @PathVariable String groupId,
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId,
            @RequestParam MultipartFile file,
            @RequestParam(defaultValue = "true") boolean encrypted,
            @RequestParam(required = false) String encryptionAlgorithm,
            @RequestParam(required = false) String kdfAlgorithm,
            @RequestParam(required = false) String kdfSalt,
            @RequestParam(required = false) String nonce,
            @RequestParam(required = false) String sha256,
            @RequestParam(required = false) Long plainSizeBytes,
            @RequestParam(required = false) Integer expiryHours) {
        return groupService.uploadFile(
                groupId,
                fingerprintId,
                file,
                encrypted,
                encryptionAlgorithm,
                kdfAlgorithm,
                kdfSalt,
                nonce,
                sha256,
                plainSizeBytes,
                expiryHours);
    }

    @GetMapping("/{groupId}/files/{fileId}/download")
    public ResponseEntity<?> downloadFile(
            @PathVariable String groupId,
            @PathVariable String fileId,
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId) {
        return ShareController.downloadResponse(groupService.downloadFile(groupId, fileId, fingerprintId));
    }

    @PutMapping("/{groupId}/key-backups/me")
    public GroupKeyBackupResponse upsertKeyBackup(
            @PathVariable String groupId,
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId,
            @Valid @RequestBody GroupKeyBackupRequest request) {
        return groupService.upsertKeyBackup(groupId, fingerprintId, request);
    }

    @GetMapping("/key-backups/mine")
    public List<GroupKeyBackupResponse> myKeyBackups(
            @RequestHeader(name = "X-CourseDrop-Fingerprint-Id") String fingerprintId) {
        return groupService.listMyKeyBackups(fingerprintId);
    }
}
