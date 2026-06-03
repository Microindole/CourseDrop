package com.coursedrop.server.mapper;

import java.time.Instant;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.coursedrop.server.entity.GroupEntity;
import com.coursedrop.server.enums.GroupStatus;
import com.coursedrop.server.group.GroupRecord;

@Repository
public class GroupRepository {
    private final GroupMapper mapper;

    public GroupRepository(GroupMapper mapper) {
        this.mapper = mapper;
    }

    public void save(GroupRecord group) {
        mapper.insert(toEntity(group));
    }

    public Optional<GroupRecord> findById(String id) {
        return Optional.ofNullable(mapper.selectById(id)).map(this::toRecord);
    }

    private GroupEntity toEntity(GroupRecord record) {
        var entity = new GroupEntity();
        entity.setId(record.id());
        entity.setEncryptedName(record.encryptedName());
        entity.setNameIv(record.nameIv());
        entity.setNameAuthTag(record.nameAuthTag());
        entity.setCreatorId(record.creatorId());
        entity.setStatus(record.status().name());
        entity.setConfigJson(record.configJson());
        entity.setCreatedAt(record.createdAt().toString());
        return entity;
    }

    private GroupRecord toRecord(GroupEntity entity) {
        return new GroupRecord(
                entity.getId(),
                entity.getEncryptedName(),
                entity.getNameIv(),
                entity.getNameAuthTag(),
                entity.getCreatorId(),
                GroupStatus.valueOf(entity.getStatus()),
                entity.getConfigJson(),
                Instant.parse(entity.getCreatedAt()));
    }
}
