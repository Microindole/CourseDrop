package com.coursedrop.server.service;

import java.time.Instant;
import java.util.HashSet;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.coursedrop.server.mapper.RoomRepository;
import com.coursedrop.server.mapper.TransferItemRepository;
import com.coursedrop.server.storage.LocalFileStorageService;

@Service
public class CleanupService {
    private final TransferItemRepository transferItemRepository;
    private final RoomRepository roomRepository;
    private final LocalFileStorageService storageService;
    private final ShareService shareService;
    private final GroupService groupService;

    public CleanupService(
            TransferItemRepository transferItemRepository,
            RoomRepository roomRepository,
            LocalFileStorageService storageService,
            ShareService shareService,
            GroupService groupService) {
        this.transferItemRepository = transferItemRepository;
        this.roomRepository = roomRepository;
        this.storageService = storageService;
        this.shareService = shareService;
        this.groupService = groupService;
    }

    @Scheduled(fixedDelayString = "PT30M")
    public void cleanupExpiredItems() {
        var now = Instant.now();
        transferItemRepository.findExpired(now).stream()
                .filter(item -> item.storageKey() != null)
                .forEach(item -> storageService.deleteIfExists(item.storageKey()));
        transferItemRepository.deleteExpired(now);
        shareService.cleanupExpired(now);
        groupService.cleanupExpired(now);
        cleanupOrphanFiles();
        roomRepository.deleteExpired(now);
    }

    private void cleanupOrphanFiles() {
        var referencedKeys = new HashSet<String>();
        transferItemRepository.findAll().stream()
                .filter(item -> item.storageKey() != null)
                .map(item -> item.storageKey())
                .forEach(referencedKeys::add);
        shareService.listReferencedStorageKeys().forEach(referencedKeys::add);
        groupService.listReferencedStorageKeys().forEach(referencedKeys::add);
        storageService.listStorageKeys().stream()
                .filter(key -> !referencedKeys.contains(key))
                .forEach(storageService::deleteIfExists);
    }
}
