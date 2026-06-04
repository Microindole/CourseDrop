package com.coursedrop.server.mapper;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.coursedrop.server.entity.GroupMemberEntity;
import com.coursedrop.server.enums.GroupMemberRole;
import com.coursedrop.server.enums.GroupMemberStatus;
import com.coursedrop.server.group.GroupMemberRecord;

@Repository
public class GroupMemberRepository {
    private final GroupMemberMapper mapper;

    public GroupMemberRepository(GroupMemberMapper mapper) {
        this.mapper = mapper;
    }

    public void save(GroupMemberRecord member) {
        mapper.insert(toEntity(member));
    }

    public List<GroupMemberRecord> findByGroupId(String groupId) {
        return mapper.selectList(new LambdaQueryWrapper<GroupMemberEntity>()
                .eq(GroupMemberEntity::getGroupId, groupId)
                .orderByAsc(GroupMemberEntity::getJoinedAt))
                .stream()
                .map(this::toRecord)
                .toList();
    }

    public List<GroupMemberRecord> findActiveByFingerprintId(String fingerprintId) {
        return mapper.selectList(new LambdaQueryWrapper<GroupMemberEntity>()
                .eq(GroupMemberEntity::getFingerprintId, fingerprintId)
                .eq(GroupMemberEntity::getStatus, GroupMemberStatus.ACTIVE.name())
                .orderByDesc(GroupMemberEntity::getJoinedAt))
                .stream()
                .map(this::toRecord)
                .toList();
    }

    public Optional<GroupMemberRecord> findActive(String groupId, String fingerprintId) {
        return Optional.ofNullable(mapper.selectOne(new LambdaQueryWrapper<GroupMemberEntity>()
                .eq(GroupMemberEntity::getGroupId, groupId)
                .eq(GroupMemberEntity::getFingerprintId, fingerprintId)
                .eq(GroupMemberEntity::getStatus, GroupMemberStatus.ACTIVE.name())))
                .map(this::toRecord);
    }

    public void markLeft(String groupId, String fingerprintId, Instant leftAt) {
        mapper.update(new LambdaUpdateWrapper<GroupMemberEntity>()
                .eq(GroupMemberEntity::getGroupId, groupId)
                .eq(GroupMemberEntity::getFingerprintId, fingerprintId)
                .set(GroupMemberEntity::getStatus, GroupMemberStatus.LEFT.name())
                .set(GroupMemberEntity::getLeftAt, leftAt.toString()));
    }

    private GroupMemberEntity toEntity(GroupMemberRecord record) {
        var entity = new GroupMemberEntity();
        entity.setId(record.groupId() + ":" + record.fingerprintId());
        entity.setGroupId(record.groupId());
        entity.setFingerprintId(record.fingerprintId());
        entity.setRole(record.role().name());
        entity.setStatus(record.status().name());
        entity.setJoinedAt(record.joinedAt().toString());
        entity.setLeftAt(record.leftAt() == null ? null : record.leftAt().toString());
        return entity;
    }

    private GroupMemberRecord toRecord(GroupMemberEntity entity) {
        return new GroupMemberRecord(
                entity.getGroupId(),
                entity.getFingerprintId(),
                GroupMemberRole.valueOf(entity.getRole()),
                GroupMemberStatus.valueOf(entity.getStatus()),
                Instant.parse(entity.getJoinedAt()),
                entity.getLeftAt() == null ? null : Instant.parse(entity.getLeftAt()));
    }
}
