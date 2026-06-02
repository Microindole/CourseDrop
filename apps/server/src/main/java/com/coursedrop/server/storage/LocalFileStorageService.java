package com.coursedrop.server.storage;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.coursedrop.server.common.ApiException;
import com.coursedrop.server.config.StorageProperties;

@Service
public class LocalFileStorageService {
    private final Path uploadRoot;

    public LocalFileStorageService(StorageProperties storageProperties) {
        this.uploadRoot = Path.of(storageProperties.uploadDir()).toAbsolutePath().normalize();
    }

    public StoredObject store(MultipartFile file) {
        try {
            Files.createDirectories(uploadRoot);
            var safeName = FileNameCleaner.clean(file.getOriginalFilename());
            var storageKey = safeName.isBlank()
                    ? UUID.randomUUID().toString()
                    : UUID.randomUUID() + "-" + safeName;
            var target = uploadRoot.resolve(storageKey).normalize();
            file.transferTo(target);
            return new StoredObject(storageKey, target, Files.size(target));
        } catch (IOException exception) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store file");
        }
    }

    public Path resolve(String storageKey) {
        var path = uploadRoot.resolve(storageKey).normalize();
        if (!path.startsWith(uploadRoot) || !Files.exists(path)) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Stored file not found");
        }
        return path;
    }

    public void deleteIfExists(String storageKey) {
        try {
            Files.deleteIfExists(uploadRoot.resolve(storageKey).normalize());
        } catch (IOException ignored) {
            // Cleanup should be best-effort; metadata cleanup can still continue.
        }
    }

    public boolean deleteIfExistsWithResult(String storageKey) {
        try {
            return Files.deleteIfExists(uploadRoot.resolve(storageKey).normalize());
        } catch (IOException exception) {
            return false;
        }
    }

    public List<String> listStorageKeys() {
        try {
            if (!Files.exists(uploadRoot)) {
                return List.of();
            }
            try (var stream = Files.list(uploadRoot)) {
                return stream
                        .filter(Files::isRegularFile)
                        .map(path -> path.getFileName().toString())
                        .toList();
            }
        } catch (IOException exception) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to list stored files");
        }
    }
}
