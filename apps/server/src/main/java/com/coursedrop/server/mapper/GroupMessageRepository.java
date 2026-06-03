package com.coursedrop.server.mapper;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.coursedrop.server.entity.GroupMessageEntity;
import com.coursedrop.server.enums.GroupMessageType;
import com.coursedrop.server.group.GroupMessageRecord;

@Repository
public class GroupMessageRepository {
    private final GroupMessageMapper mapper;

    public GroupMessageRepository(GroupMessageMapper mapper) {
        this.mapper = mapper;
    }

    public void save(GroupMessageRecord message) {
        mapper.insert(toEntity(message));
    }

    public Optional<GroupMessageRecord> findById(String id) {
        return Optional.ofNullable(mapper.selectById(id)).map(this::toRecord);
    }

    public List<GroupMessageRecord> findByGroupIdAfter(String groupId, String afterCreatedAt) {
        var query = new LambdaQueryWrapper<GroupMessageEntity>()
                .eq(GroupMessageEntity::getGroupId, groupId)
                .orderByAsc(GroupMessageEntity::getCreatedAt);
        if (afterCreatedAt != null && !afterCreatedAt.isBlank()) {
            query.gt(GroupMessageEntity::getCreatedAt, afterCreatedAt);
        }
        return mapper.selectList(query)
                .stream()
                .map(this::toRecord)
                .toList();
    }

    private GroupMessageEntity toEntity(GroupMessageRecord record) {
        var entity = new GroupMessageEntity();
        entity.setId(record.id());
        entity.setGroupId(record.groupId());
        entity.setSenderId(record.senderId());
        entity.setType(record.type().name());
        entity.setIv(record.iv());
        entity.setAuthTag(record.authTag());
        entity.setEncryptedPayload(record.encryptedPayload());
        entity.setCreatedAt(record.createdAt().toString());
        return entity;
    }

    private GroupMessageRecord toRecord(GroupMessageEntity entity) {
        return new GroupMessageRecord(
                entity.getId(),
                entity.getGroupId(),
                entity.getSenderId(),
                GroupMessageType.valueOf(entity.getType()),
                entity.getIv(),
                entity.getAuthTag(),
                entity.getEncryptedPayload(),
                Instant.parse(entity.getCreatedAt()));
    }
}
