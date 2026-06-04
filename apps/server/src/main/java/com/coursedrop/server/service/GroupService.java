package com.coursedrop.server.service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import org.springframework.core.io.PathResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.coursedrop.server.common.ApiException;
import com.coursedrop.server.config.StorageProperties;
import com.coursedrop.server.dto.CreateGroupRequest;
import com.coursedrop.server.dto.GroupFileResponse;
import com.coursedrop.server.dto.GroupMembershipResponse;
import com.coursedrop.server.dto.GroupMemberResponse;
import com.coursedrop.server.dto.GroupMessageRequest;
import com.coursedrop.server.dto.GroupMessageResponse;
import com.coursedrop.server.dto.GroupMessageSyncResponse;
import com.coursedrop.server.dto.GroupResponse;
import com.coursedrop.server.enums.GroupMemberRole;
import com.coursedrop.server.enums.GroupMemberStatus;
import com.coursedrop.server.enums.GroupStatus;
import com.coursedrop.server.group.GroupFileRecord;
import com.coursedrop.server.group.GroupMemberRecord;
import com.coursedrop.server.group.GroupMessageRecord;
import com.coursedrop.server.group.GroupRealtimeEvent;
import com.coursedrop.server.group.GroupRealtimeNotifier;
import com.coursedrop.server.group.GroupRecord;
import com.coursedrop.server.mapper.GroupFileRepository;
import com.coursedrop.server.mapper.GroupMemberRepository;
import com.coursedrop.server.mapper.GroupMessageRepository;
import com.coursedrop.server.mapper.GroupRepository;
import com.coursedrop.server.mapper.IdentityRepository;
import com.coursedrop.server.storage.LocalFileStorageService;
import com.coursedrop.server.transfer.DownloadFile;

@Service
public class GroupService {
    private final GroupRepository groupRepository;
    private final GroupMemberRepository memberRepository;
    private final GroupMessageRepository messageRepository;
    private final GroupFileRepository fileRepository;
    private final IdentityRepository identityRepository;
    private final LocalFileStorageService storageService;
    private final StorageProperties storageProperties;
    private final GroupRealtimeNotifier realtimeNotifier;

    public GroupService(
            GroupRepository groupRepository,
            GroupMemberRepository memberRepository,
            GroupMessageRepository messageRepository,
            GroupFileRepository fileRepository,
            IdentityRepository identityRepository,
            LocalFileStorageService storageService,
            StorageProperties storageProperties,
            GroupRealtimeNotifier realtimeNotifier) {
        this.groupRepository = groupRepository;
        this.memberRepository = memberRepository;
        this.messageRepository = messageRepository;
        this.fileRepository = fileRepository;
        this.identityRepository = identityRepository;
        this.storageService = storageService;
        this.storageProperties = storageProperties;
        this.realtimeNotifier = realtimeNotifier;
    }

    public GroupResponse create(CreateGroupRequest request) {
        requireFingerprint(request.creatorId());
        var now = Instant.now();
        var group = new GroupRecord(
                UUID.randomUUID().toString(),
                request.encryptedName(),
                request.nameIv(),
                request.nameAuthTag(),
                request.creatorId(),
                GroupStatus.ACTIVE,
                request.configJson(),
                now);
        groupRepository.save(group);
        memberRepository.save(new GroupMemberRecord(
                group.id(),
                request.creatorId(),
                GroupMemberRole.OWNER,
                GroupMemberStatus.ACTIVE,
                now,
                null));
        return toResponse(group);
    }

    public GroupResponse get(String groupId) {
        return toResponse(requireGroup(groupId));
    }

    public List<GroupMembershipResponse> listMine(String fingerprintId) {
        requireFingerprint(fingerprintId);
        return memberRepository.findActiveByFingerprintId(fingerprintId)
                .stream()
                .map(member -> new GroupMembershipResponse(toResponse(requireGroup(member.groupId())), toResponse(member)))
                .toList();
    }

    public GroupMemberResponse join(String groupId, String fingerprintId) {
        requireGroup(groupId);
        requireFingerprint(fingerprintId);
        var existing = memberRepository.findActive(groupId, fingerprintId);
        if (existing.isPresent()) {
            return toResponse(existing.get());
        }
        var member = new GroupMemberRecord(
                groupId,
                fingerprintId,
                GroupMemberRole.MEMBER,
                GroupMemberStatus.ACTIVE,
                Instant.now(),
                null);
        memberRepository.save(member);
        return toResponse(member);
    }

    public void leave(String groupId, String fingerprintId) {
        requireActiveMember(groupId, fingerprintId);
        memberRepository.markLeft(groupId, fingerprintId, Instant.now());
    }

    public GroupMessageResponse sendMessage(String groupId, GroupMessageRequest request) {
        requireActiveMember(groupId, request.senderId());
        var message = new GroupMessageRecord(
                request.id(),
                groupId,
                request.senderId(),
                request.type(),
                request.iv(),
                request.authTag(),
                request.encryptedPayload(),
                Instant.now());
        messageRepository.save(message);
        notifyMessageCreated(message);
        return toResponse(message);
    }

    public GroupMessageSyncResponse syncMessages(String groupId, String fingerprintId, String after) {
        requireActiveMember(groupId, fingerprintId);
        var messages = messageRepository.findByGroupIdAfter(groupId, after)
                .stream()
                .map(this::toResponse)
                .toList();
        var nextCursor = messages.isEmpty() ? (after == null ? "" : after) : messages.get(messages.size() - 1).createdAt().toString();
        return new GroupMessageSyncResponse(messages, nextCursor);
    }

    public GroupFileResponse uploadFile(
            String groupId,
            String uploaderId,
            MultipartFile file,
            boolean encrypted,
            String encryptionAlgorithm,
            String kdfAlgorithm,
            String kdfSalt,
            String nonce,
            String sha256,
            Long plainSizeBytes,
            Integer expiryHours) {
        requireActiveMember(groupId, uploaderId);
        if (file.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "File is empty");
        }
        var maxBytes = storageProperties.maxFileSizeMb() * 1024L * 1024L;
        if (file.getSize() > maxBytes) {
            throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "File is too large");
        }
        validateEncryptionMetadata(encrypted, encryptionAlgorithm, kdfAlgorithm, kdfSalt, nonce, sha256, plainSizeBytes);
        var storedObject = storageService.store(file);
        var now = Instant.now();
        var ttlHours = expiryHours == null || expiryHours < 1 ? storageProperties.fileTtlHours() : expiryHours;
        var record = new GroupFileRecord(
                UUID.randomUUID().toString(),
                groupId,
                uploaderId,
                storedObject.storageKey(),
                file.getContentType(),
                storedObject.sizeBytes(),
                encrypted,
                blankToNull(encryptionAlgorithm),
                blankToNull(kdfAlgorithm),
                blankToNull(kdfSalt),
                blankToNull(nonce),
                blankToNull(sha256),
                plainSizeBytes,
                now,
                now.plus(ttlHours, ChronoUnit.HOURS));
        fileRepository.save(record);
        return toResponse(record);
    }

    public DownloadFile downloadFile(String groupId, String fileId, String fingerprintId) {
        requireActiveMember(groupId, fingerprintId);
        var file = fileRepository.findById(fileId)
                .filter(value -> value.groupId().equals(groupId))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Group file not found"));
        if (file.expiresAt().isBefore(Instant.now())) {
            throw new ApiException(HttpStatus.GONE, "Group file expired");
        }
        return new DownloadFile("group-file-" + file.id() + ".bin", file.contentType(),
                new PathResource(storageService.resolve(file.storageKey())));
    }

    public void cleanupExpired(Instant now) {
        fileRepository.findExpired(now).forEach(file -> storageService.deleteIfExists(file.storageKey()));
        fileRepository.deleteExpired(now);
    }

    public List<String> listReferencedStorageKeys() {
        return fileRepository.findAll().stream()
                .map(GroupFileRecord::storageKey)
                .toList();
    }

    private GroupRecord requireGroup(String groupId) {
        return groupRepository.findById(groupId)
                .filter(group -> group.status() == GroupStatus.ACTIVE)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Group not found"));
    }

    private void requireFingerprint(String fingerprintId) {
        if (fingerprintId == null || fingerprintId.isBlank()) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Fingerprint is required");
        }
        identityRepository.findFingerprintById(fingerprintId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Unknown fingerprint"));
    }

    private void requireActiveMember(String groupId, String fingerprintId) {
        requireGroup(groupId);
        requireFingerprint(fingerprintId);
        memberRepository.findActive(groupId, fingerprintId)
                .orElseThrow(() -> new ApiException(HttpStatus.FORBIDDEN, "Group membership required"));
    }

    private void validateEncryptionMetadata(
            boolean encrypted,
            String encryptionAlgorithm,
            String kdfAlgorithm,
            String kdfSalt,
            String nonce,
            String sha256,
            Long plainSizeBytes) {
        if (!encrypted) {
            return;
        }
        var saltRequired = !"NONE-RAW-KEY".equalsIgnoreCase(kdfAlgorithm);
        if (isBlank(encryptionAlgorithm) || isBlank(kdfAlgorithm) || (saltRequired && isBlank(kdfSalt))
                || isBlank(nonce) || isBlank(sha256) || plainSizeBytes == null || plainSizeBytes < 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Encrypted group file metadata is incomplete");
        }
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private GroupResponse toResponse(GroupRecord group) {
        return new GroupResponse(
                group.id(),
                group.encryptedName(),
                group.nameIv(),
                group.nameAuthTag(),
                group.creatorId(),
                group.status(),
                group.configJson(),
                group.createdAt());
    }

    private GroupMemberResponse toResponse(GroupMemberRecord member) {
        return new GroupMemberResponse(
                member.groupId(),
                member.fingerprintId(),
                member.role(),
                member.status(),
                member.joinedAt(),
                member.leftAt());
    }

    private GroupMessageResponse toResponse(GroupMessageRecord message) {
        return new GroupMessageResponse(
                message.id(),
                message.groupId(),
                message.senderId(),
                message.type(),
                message.iv(),
                message.authTag(),
                message.encryptedPayload(),
                message.createdAt());
    }

    private void notifyMessageCreated(GroupMessageRecord message) {
        var memberIds = memberRepository.findByGroupId(message.groupId())
                .stream()
                .filter(member -> member.status() == GroupMemberStatus.ACTIVE)
                .map(GroupMemberRecord::fingerprintId)
                .toList();
        realtimeNotifier.notifyMembers(memberIds, new GroupRealtimeEvent(
                "GROUP_MESSAGE_CREATED",
                message.groupId(),
                toResponse(message)));
    }

    private GroupFileResponse toResponse(GroupFileRecord file) {
        return new GroupFileResponse(
                file.id(),
                file.groupId(),
                file.contentType(),
                file.sizeBytes(),
                file.encrypted(),
                file.encryptionAlgorithm(),
                file.kdfAlgorithm(),
                file.kdfSalt(),
                file.nonce(),
                file.sha256(),
                file.plainSizeBytes(),
                file.createdAt(),
                file.expiresAt());
    }
}
