package com.coursedrop.server.mapper;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.coursedrop.server.entity.GroupKeyBackupEntity;
import com.coursedrop.server.group.GroupKeyBackupRecord;

@Repository
public class GroupKeyBackupRepository {
    private final GroupKeyBackupMapper mapper;

    public GroupKeyBackupRepository(GroupKeyBackupMapper mapper) {
        this.mapper = mapper;
    }

    public void upsert(GroupKeyBackupRecord backup) {
        var existing = findByAccountAndGroup(backup.accountId(), backup.groupId());
        if (existing.isEmpty()) {
            mapper.insert(toEntity(backup));
            return;
        }
        mapper.update(new LambdaUpdateWrapper<GroupKeyBackupEntity>()
                .eq(GroupKeyBackupEntity::getAccountId, backup.accountId())
                .eq(GroupKeyBackupEntity::getGroupId, backup.groupId())
                .set(GroupKeyBackupEntity::getFingerprintId, backup.fingerprintId())
                .set(GroupKeyBackupEntity::getAlgorithm, backup.algorithm())
                .set(GroupKeyBackupEntity::getKdfAlgorithm, backup.kdfAlgorithm())
                .set(GroupKeyBackupEntity::getKdfSalt, backup.kdfSalt())
                .set(GroupKeyBackupEntity::getIv, backup.iv())
                .set(GroupKeyBackupEntity::getAuthTag, backup.authTag())
                .set(GroupKeyBackupEntity::getEncryptedPayload, backup.encryptedPayload())
                .set(GroupKeyBackupEntity::getUpdatedAt, backup.updatedAt().toString()));
    }

    public Optional<GroupKeyBackupRecord> findByAccountAndGroup(String accountId, String groupId) {
        return Optional.ofNullable(mapper.selectOne(new LambdaQueryWrapper<GroupKeyBackupEntity>()
                .eq(GroupKeyBackupEntity::getAccountId, accountId)
                .eq(GroupKeyBackupEntity::getGroupId, groupId)))
                .map(this::toRecord);
    }

    public List<GroupKeyBackupRecord> findByAccountId(String accountId) {
        return mapper.selectList(new LambdaQueryWrapper<GroupKeyBackupEntity>()
                .eq(GroupKeyBackupEntity::getAccountId, accountId)
                .orderByDesc(GroupKeyBackupEntity::getUpdatedAt))
                .stream()
                .map(this::toRecord)
                .toList();
    }

    private GroupKeyBackupEntity toEntity(GroupKeyBackupRecord record) {
        var entity = new GroupKeyBackupEntity();
        entity.setId(record.id());
        entity.setAccountId(record.accountId());
        entity.setFingerprintId(record.fingerprintId());
        entity.setGroupId(record.groupId());
        entity.setAlgorithm(record.algorithm());
        entity.setKdfAlgorithm(record.kdfAlgorithm());
        entity.setKdfSalt(record.kdfSalt());
        entity.setIv(record.iv());
        entity.setAuthTag(record.authTag());
        entity.setEncryptedPayload(record.encryptedPayload());
        entity.setCreatedAt(record.createdAt().toString());
        entity.setUpdatedAt(record.updatedAt().toString());
        return entity;
    }

    private GroupKeyBackupRecord toRecord(GroupKeyBackupEntity entity) {
        return new GroupKeyBackupRecord(
                entity.getId(),
                entity.getAccountId(),
                entity.getFingerprintId(),
                entity.getGroupId(),
                entity.getAlgorithm(),
                entity.getKdfAlgorithm(),
                entity.getKdfSalt(),
                entity.getIv(),
                entity.getAuthTag(),
                entity.getEncryptedPayload(),
                Instant.parse(entity.getCreatedAt()),
                Instant.parse(entity.getUpdatedAt()));
    }
}
