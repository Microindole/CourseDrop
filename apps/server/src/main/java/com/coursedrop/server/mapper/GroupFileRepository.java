package com.coursedrop.server.mapper;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.coursedrop.server.entity.GroupFileEntity;
import com.coursedrop.server.group.GroupFileRecord;

@Repository
public class GroupFileRepository {
    private final GroupFileMapper mapper;

    public GroupFileRepository(GroupFileMapper mapper) {
        this.mapper = mapper;
    }

    public void save(GroupFileRecord file) {
        mapper.insert(toEntity(file));
    }

    public Optional<GroupFileRecord> findById(String id) {
        return Optional.ofNullable(mapper.selectById(id)).map(this::toRecord);
    }

    public List<GroupFileRecord> findByGroupId(String groupId) {
        return mapper.selectList(new LambdaQueryWrapper<GroupFileEntity>()
                .eq(GroupFileEntity::getGroupId, groupId)
                .orderByDesc(GroupFileEntity::getCreatedAt))
                .stream()
                .map(this::toRecord)
                .toList();
    }

    public List<GroupFileRecord> findAll() {
        return mapper.selectList(new LambdaQueryWrapper<GroupFileEntity>())
                .stream()
                .map(this::toRecord)
                .toList();
    }

    public List<GroupFileRecord> findExpired(Instant now) {
        return mapper.selectList(new LambdaQueryWrapper<GroupFileEntity>()
                .lt(GroupFileEntity::getExpiresAt, now.toString()))
                .stream()
                .map(this::toRecord)
                .toList();
    }

    public void deleteById(String id) {
        mapper.deleteById(id);
    }

    public int deleteExpired(Instant now) {
        return mapper.delete(new LambdaQueryWrapper<GroupFileEntity>()
                .lt(GroupFileEntity::getExpiresAt, now.toString()));
    }

    private GroupFileEntity toEntity(GroupFileRecord record) {
        var entity = new GroupFileEntity();
        entity.setId(record.id());
        entity.setGroupId(record.groupId());
        entity.setUploaderId(record.uploaderId());
        entity.setStorageKey(record.storageKey());
        entity.setContentType(record.contentType());
        entity.setSizeBytes(record.sizeBytes());
        entity.setEncrypted(record.encrypted() ? 1 : 0);
        entity.setEncryptionAlgorithm(record.encryptionAlgorithm());
        entity.setKdfAlgorithm(record.kdfAlgorithm());
        entity.setKdfSalt(record.kdfSalt());
        entity.setNonce(record.nonce());
        entity.setSha256(record.sha256());
        entity.setPlainSizeBytes(record.plainSizeBytes());
        entity.setCreatedAt(record.createdAt().toString());
        entity.setExpiresAt(record.expiresAt().toString());
        return entity;
    }

    private GroupFileRecord toRecord(GroupFileEntity entity) {
        return new GroupFileRecord(
                entity.getId(),
                entity.getGroupId(),
                entity.getUploaderId(),
                entity.getStorageKey(),
                entity.getContentType(),
                entity.getSizeBytes(),
                entity.getEncrypted() != null && entity.getEncrypted() == 1,
                entity.getEncryptionAlgorithm(),
                entity.getKdfAlgorithm(),
                entity.getKdfSalt(),
                entity.getNonce(),
                entity.getSha256(),
                entity.getPlainSizeBytes(),
                Instant.parse(entity.getCreatedAt()),
                Instant.parse(entity.getExpiresAt()));
    }
}
