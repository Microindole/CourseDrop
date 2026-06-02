package com.coursedrop.server.storage;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

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
            var storageKey = nextStorageKey();
            var target = uploadRoot.resolve(storageKey).normalize();
            if (!target.startsWith(uploadRoot)) {
                throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Invalid storage path");
            }
            Files.createDirectories(target.getParent());
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
            deletePath(storageKey);
        } catch (IOException ignored) {
            // Cleanup should be best-effort; metadata cleanup can still continue.
        }
    }

    public boolean deleteIfExistsWithResult(String storageKey) {
        try {
            return deletePath(storageKey);
        } catch (IOException exception) {
            return false;
        }
    }

    public List<String> listStorageKeys() {
        try {
            if (!Files.exists(uploadRoot)) {
                return List.of();
            }
            try (Stream<Path> stream = Files.walk(uploadRoot)) {
                return stream
                        .filter(Files::isRegularFile)
                        .map(path -> uploadRoot.relativize(path).toString().replace('\\', '/'))
                        .toList();
            }
        } catch (IOException exception) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to list stored files");
        }
    }

    private String nextStorageKey() {
        var id = UUID.randomUUID().toString().replace("-", "");
        return id.substring(0, 2) + "/" + id.substring(2, 4) + "/" + id + ".bin";
    }

    private boolean deletePath(String storageKey) throws IOException {
        var path = uploadRoot.resolve(storageKey).normalize();
        if (!path.startsWith(uploadRoot)) {
            return false;
        }
        var deleted = Files.deleteIfExists(path);
        deleteEmptyParentDirectories(path.getParent());
        return deleted;
    }

    private void deleteEmptyParentDirectories(Path directory) throws IOException {
        var current = directory;
        while (current != null && current.startsWith(uploadRoot) && !current.equals(uploadRoot)) {
            try (var stream = Files.list(current)) {
                if (stream.findAny().isPresent()) {
                    return;
                }
            }
            Files.deleteIfExists(current);
            current = current.getParent();
        }
    }
}
